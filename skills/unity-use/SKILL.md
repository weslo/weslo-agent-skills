---
name: unity-use
description: Read before driving a Unity editor or development player from an agent session, through the Unity CLI (`unity status`, `unity command …`, `eval`) or the Unity MCP. It covers launching the editor for automation and checking it is healthy; the 5 s limit on every command and what a timeout does and doesn't mean; domain reloads; compiling and running tests; waiting on long work without polling; writing `eval` snippets that compile; which files only the editor may change; and piloting a development player. Use it before the first editor command of a session, and again whenever a command times out, stalls, or the editor drops. Command syntax and flags are in the `unity-cli` skill.
---

# Using Unity from an agent session

This skill is the discipline for driving a Unity editor reliably. The `unity-cli` skill documents the commands themselves. Project-specific flows, such as play setups, test recipes and which assets matter, live in the project's own agent guidance (`AGENTS.md`). Where the two disagree, the project's guidance wins.

## Before the first command
1. Run `unity status` and expect `ready`.
2. Check that the editor was launched for automation:
   ```bash
   pgrep -f "Unity.app/Contents/MacOS/Unity.*-automated"
   ```
   No output means a person opened it from the Hub or the Dock. That is the most common cause of stalls and half-failing commands, so rule it out before diagnosing anything else.
3. If no editor is running, launch one yourself: `unity open . --args "-automated"`. It reaches `ready` in 15 seconds to a minute, and the Unity MCP comes back with it. `-automated` stops modal dialogs from stalling commands.
4. If an editor is running without the flag, ask the user before closing it, because unsaved work is lost. Then:
   - Close it with `kill <pid>`. AppleScript `quit` and an `eval` of `EditorApplication.Exit(0)` don't close it.
   - Relaunch with the command above.

## The 5 s limit
Every `unity command` call runs on the editor's main thread and is limited to 5 s, however the editor was launched. A healthy call takes about 0.6 to 1.6 s.

**What a timeout means.** A longer call fails with "Main thread operation timed out after 5000ms".
- The message means the *reply* timed out. It never means the code was rejected, and the work usually finishes anyway.
- Check the side effects (the file it writes, `git status`) before retrying, or you will do the work twice.
- The next call queues behind the slow one until it finishes.
- `eval_file --timeout` does not raise the limit.

**Long work.** Never put long work in a single call. Start it inside the editor so it runs on its own: for example, register an `EditorApplication.update` callback that does a slice per frame and writes its result to a file. Then wait for the file in the background (see Waiting).

**Short calls landing near 5 s on an automated editor:**
1. Run `unity command editor_focus` once.
2. If calls still land at almost exactly 5 s, macOS is throttling an editor whose window is hidden. Run `open "/Applications/Unity/Hub/Editor/<version>/Unity.app"`, which activates the running editor without relaunching it.

The signature of this state is `editor_status` answering instantly while `eval` times out.

## Domain reloads
- Compiling scripts, and entering or leaving play mode, reload the domain.
  - During a reload `unity status` reports `unreachable` for roughly 12 to 14 s, and the Unity MCP reports "Unity not detected".
  - Wait for `ready` instead of diagnosing.
- Never enter play mode with script edits pending. Refresh, wait for the compile to finish, check that the console is clean, then enter.
- State set from a script right after entering play mode can be wiped by a reload during entry. Check it again afterwards.

## Compiling and testing
- **Compile through the editor**, never on your own: run `unity command recompile`, then poll `recompile_status` until `completed` or `up_to_date`. This works while the editor is unfocused.
  - A 3 s `completed` can be a real compile. The first time in a session, confirm it from the assembly's modification time under `Library/ScriptAssemblies/`.
- **New files:** after creating files under `Assets`, run `unity command eval 'UnityEditor.AssetDatabase.Refresh();'` so the editor imports them and writes their `.meta` files. An asmdef edit followed by a refresh compiles on its own.
- **Safe Mode:** compile errors put the editor in Safe Mode, where the CLI can't connect. The `unity-cli` skill has the recovery steps.
- **Tests:** run them only in the open editor. Start with `unity command run_tests --mode EditMode --async_tests true`, then poll `test_status` until `status` is `completed`.
- **Recheck edited assets.** A test run or play session can put an edited prefab or scene back to its saved state. Hash the assets you edited before and after editor runs, and diff them right before committing.

## Waiting without polling
Never run a sleep loop in the foreground, and never repeat a status call turn after turn.
- **A long command** (tests, a build, a compile you must wait for): run it in the background, as one script that starts the job, polls until it finishes, and prints the result. The session is woken when the script exits.
- **A condition inside the editor:** `unity command wait_for` checks it on the editor's own frame loop. A synchronous wait blocks every other command until it resolves, so pass `async=true` and poll `wait_status`. Async waits don't survive a domain reload.
- **A condition outside the editor:** use the Monitor tool with an until-condition.

## Writing `eval` snippets
An `eval` snippet is the body of a method:
- A `using` directive is a compile error, so fully qualify every type, e.g. `System.Text.StringBuilder` and `UnityEngine.GameObject`.
- A bare `Object` is ambiguous; write `UnityEngine.Object`.
- `return` a value to get it back in the result.

Other rules:
- `Debug.Log` output does not come back. Return a string, or write longer output to a file with `System.IO.File.WriteAllText` and read the file.
- Keep each call well under 5 s.
- `eval` has no sandbox and references the project's assemblies, so prefer it to the MCP's `Unity_RunCommand`, which can't reference project assemblies or use reflection.
- Prefer the project's public entry points to reflecting into private members. Private names change without a compile error to warn you.
- Probes that sample animation: an Animator on a model instantiated straight from an FBX defaults to `CullUpdateTransforms` and doesn't evaluate off camera. Set `AlwaysAnimate`, and check that some bone moves before trusting the samples.

## Files only the editor may change
- **Which files:** scenes, prefabs, `.asset` and `.meta` files, `ProjectSettings`, and the package manifests.
- **How to change them:** only through the editor: `AssetDatabase`, `PrefabUtility` (`LoadPrefabContents`, `SaveAsPrefabAsset`, `UnloadPrefabContents`) and `SerializedObject` from `eval`, or the MCP's asset tools. Reading their YAML as text is fine.
- **When the tools are down:** if both the CLI and the MCP stop working, stop and ask the user. Never route around them by hand-editing these files: that desynchronises the asset database and breaks GUID references far from the cause. A blocked task is recoverable; a corrupted project is not.

## Reading and searching
- **Text files** (C#, and Unity YAML for reading): use the built-in Read, Grep and Glob tools. They're fast and never wait on the editor.
- **Questions the editor owns:** ask the editor. That means prefab and scene hierarchy, `AssetDatabase` queries, GUID-to-path resolution and package resolution.
- **`Unity_Grep` quirks:**
  - It takes a directory, not a file. Pointed at a file it reports "No matches found", which reads like the code being absent.
  - It doesn't search `.meta` files.
- **Plan mode** asks the user to approve every MCP call, so while planning use only the built-in tools and the CLI.

## Sharing the editor
The editor runs one command at a time. Contention shows up as spurious timeouts.
- **At most one agent talks to the editor at a time.** Parallel fan-out agents get no editor access.
- **A subagent that does use the editor** sticks to pure reads: `AssetDatabase` lookups, hierarchy walks, `console`, `editor_status`.
- **Things that write even though they look like reads:** a scene load, a Selection change, `ExecuteMenuItem`, and a `SetDirty` or save.
- **When not to give a subagent access:** never while the main session is compiling or running tests.

## Development players
A development standalone build can run the same command server as the editor.
1. Turn on Project Settings › Pipeline › Runtime › `enableInBuilds`.
2. Build with Development Build checked, and launch the build.
3. Drive it with `unity command --runtime-path <path> <command>`. On macOS the path is the `.app` bundle; elsewhere it is the folder next to the executable.

Release builds leave the server out entirely.
