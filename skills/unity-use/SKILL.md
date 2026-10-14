---
name: unity-use
description: Read before driving a Unity editor or development player from an agent session, through the Unity CLI (`unity status`, `unity command …`, `eval`) or the Unity MCP. Covers which tool to use (the CLI whenever it can do the job, the MCP only for what the CLI can't); what to do when the CLI, its Pipeline package or the MCP is missing or broken (stop and walk the user through the fix, never hand-edit around it); opening, checking and restarting the editor in automation mode; the 5 s limit on every command and what a timeout does and doesn't mean; domain reloads; compiling and tests; waiting without polling; writing `eval` snippets that compile; files only the editor may change; and development players. Use it before the first editor command of a session, and whenever a command times out, stalls or the editor drops. Command syntax and flags are in the `unity-cli` skill.
---

# Using Unity from an agent session

How to drive a Unity editor reliably. The `unity-cli` skill documents the commands and their flags; this skill is the discipline around them. Project-specific flows, such as play setups, test recipes and which assets matter, live in the project's own agent guidance (`AGENTS.md`), which wins where the two disagree.

## Which tool
1. **The Unity CLI, whenever it can do the job.** It covers:
   - running C# in the editor (`eval`);
   - assets, prefabs and scenes;
   - packages, builds and tests;
   - screenshots (`capture_game_view`, `capture_scene_view`, `screenshot`);
   - opening and closing the editor.

   `unity command` lists what the connected editor exposes; `unity commands` lists the CLI's own commands. Check those lists before deciding the CLI can't do something.
2. **The Unity MCP, only for what the CLI can't do**, such as profiler analysis or AI asset generation.
3. **Never hand-editing editor-owned files** to get around either tool (see below).

Reading and searching text files with the built-in Read, Grep and Glob tools isn't driving the editor; use them freely.

## When the tooling is missing or broken
Stop and tell the user. Say what you saw and walk them through the fix. Don't work around a broken tool, and don't make the fix yourself when it changes their machine or project.

| What you see | What it means | Walk the user through |
|---|---|---|
| `unity: command not found` | The CLI isn't installed. | Installing it. The `unity-cli` skill's "Install the CLI" step has the command. |
| `unity pipeline list` shows the project without the Pipeline package, or `unity status` lists no editor while one is open | The project lacks `com.unity.pipeline`. | `unity pipeline install`. This changes the project's package manifest, so the user approves it. |
| No connection after compile errors | The editor is in Safe Mode, where the Pipeline package doesn't load. | Fixing the compile errors, then reopening. The `unity-cli` skill has the recovery steps. |
| Commands keep failing on a healthy, automated editor (not a reload, not one timeout) | Something is wrong with the CLI or the editor. | What you ran, `unity doctor`, and the end of `Editor.log`. |
| The MCP's tools are missing *(only when you are using the MCP)* | The MCP server isn't configured for this client, or the package that provides it isn't installed. | Configuring it (`unity mcp configure <client>`), or adding the package. |
| An MCP call hangs, or the MCP reports "Unity not detected" for well over 30 s outside a reload | The MCP has broken on the editor side. | Restarting the editor. Don't re-issue the hung call; check `Editor.log` first. |

**Don't wait long before stopping.** A domain reload clears in about 15 s, so if the CLI still can't connect after a minute, stop and tell the user instead of retrying.

**Never route around a broken tool by hand-editing editor-owned files unless the user explicitly says to.** A blocked task is recoverable; a corrupted project is not.

## Opening, checking and restarting the editor
1. Run `unity status`.
2. **No editor is running:** open one yourself, in automation mode, as a background command:
   ```bash
   unity open . --args "-automated"
   ```
   It reaches `ready` in 15 seconds to a minute, and the Unity MCP comes back with it. `-automated` stops modal dialogs from stalling commands.
3. **An editor is running:** check how it was launched:
   ```bash
   pgrep -f "Unity.app/Contents/MacOS/Unity.*-automated"
   ```
   - **It prints a PID:** the editor was launched for automation. Drive it.
   - **No output:** a person opened it from the Hub or the Dock. You may still drive it. If it stalls or misbehaves, restart it in automation mode with `unity close .`, then `unity open . --args "-automated"`. Typical misbehaviour: calls landing near 5 s, calls failing half the time, or calls hanging. Add `--force` to `unity close` if the editor doesn't exit.
4. **Before closing any editor, check whether it looks in use.** `unity close` exits without saving.
   - Run:
     ```bash
     unity command eval 'int dirty = 0; for (int i = 0; i < UnityEngine.SceneManagement.SceneManager.sceneCount; i++) { if (UnityEngine.SceneManagement.SceneManager.GetSceneAt(i).isDirty) { dirty++; } } return "dirtyScenes=" + dirty + " prefabStage=" + (UnityEditor.SceneManagement.PrefabStageUtility.GetCurrentPrefabStage() != null) + " playing=" + UnityEditor.EditorApplication.isPlaying;'
     ```
   - **Ask the user first** if it reports unsaved scenes, an open prefab, or play mode. Also ask if the editor was opened by hand and too broken to answer.

## The 5 s limit
Every `unity command` call runs on the editor's main thread and is limited to 5 s, however the editor was launched. A healthy call takes about 0.6–1.6 s.

**When a call runs longer**, it fails with "Main thread operation timed out after 5000ms".
- That message means the *reply* timed out, never that the code was rejected. The work usually finishes anyway.
- Check its side effects (the file it writes, `git status`) before retrying, or you'll do it twice.
- The next call queues behind the slow one until it finishes.
- `eval_file --timeout` doesn't raise the limit.

**For long work, never use one long call.** Either:
- split it into batches that each finish well under 5 s; or
- start it inside the editor so it runs by itself, for example on an `EditorApplication.update` callback that writes its result to a file, then wait for the file in the background.

**Short calls landing near 5 s on an automated editor:**
1. Run `unity command editor_focus` once.
2. If calls still land at almost exactly 5 s, macOS is throttling an editor whose window is hidden. Run `open "/Applications/Unity/Hub/Editor/<version>/Unity.app"`, which activates the running editor without relaunching it.

The signature of this state is `editor_status` answering instantly while `eval` times out.

## Domain reloads
- **What causes them:** compiling scripts, and entering or leaving play mode.
- **What you'll see:** `unity status` reports `unreachable` for roughly 12–14 s, and the Unity MCP reports "Unity not detected". Wait for `ready`; don't diagnose.
- **Before entering play mode:** never enter it with script edits pending. Refresh, wait for the compile to finish, check the console is clean, then enter.
- **Right after entering play mode:** state you set from a script can be wiped by a reload during entry. Check it again afterwards.

## Compiling and testing
- **Compiling:** do it through the editor, never on your own.
  - Run `unity command recompile`, then poll `recompile_status` until `completed` or `up_to_date`. This works while the editor is unfocused.
  - A 3 s `completed` can be a real compile. The first time in a session, confirm it from the assembly's modification time under `Library/ScriptAssemblies/`.
- **New files under `Assets`:** run `unity command eval 'UnityEditor.AssetDatabase.Refresh();'` so the editor imports them and writes their `.meta` files. An asmdef edit plus a refresh compiles on its own.
- **Tests:** run them only in the open editor. Start them with `unity command run_tests --mode EditMode --async_tests true`, then poll `test_status` until `status` is `completed`.
- **After tests or play:** a test run or play session can return an edited prefab or scene to its saved state. Hash the assets you edited before and after editor runs, and diff them right before committing.

## Waiting without polling
Never run a sleep loop in the foreground, or repeat a status call turn after turn.
- **A long command** (tests, a build, an editor launch, a compile you must wait for): run one script that starts it, polls until it's done and prints the result, as a background command. The session is woken when it exits.
- **A condition inside the editor:** `unity command wait_for` checks it on the editor's frame loop. A synchronous wait blocks every other command until it resolves, so pass `async=true` and poll `wait_status`. Async waits don't survive a domain reload.
- **A condition outside the editor:** use the Monitor tool with an until-condition.

## Writing `eval` snippets
An `eval` snippet is the body of a method.
- **No `using` directives.** They're a compile error, so fully qualify every type (`System.Text.StringBuilder`, `UnityEngine.GameObject`). A bare `Object` is ambiguous; write `UnityEngine.Object`.
- **Getting output back:** `return` a value to get it in the result. `Debug.Log` output does not come back; write longer output to a file with `System.IO.File.WriteAllText` and read it.
- **Size:** keep each call well under 5 s.
- **Prefer `eval` to the MCP's `Unity_RunCommand`.** `eval` has no sandbox and references the project's assemblies; `Unity_RunCommand` can't reference project assemblies or use reflection. In a player, `eval` doesn't reference them either; see "Development players".
- **Prefer public entry points.** Use the project's public entry points rather than reflecting into private members, whose names can change without a compile error to warn you.
- **Sampling animation:** an Animator on a model instantiated straight from an FBX defaults to `CullUpdateTransforms` and doesn't evaluate off camera. Set it to `AlwaysAnimate`, and check that some bone moves before trusting the samples.

## Files only the editor may change
- **Which files:** scenes, prefabs, `.asset` and `.meta` files, `ProjectSettings`, and the package manifests.
- **How to change them:** only through the editor. From `eval`, use `AssetDatabase`, `PrefabUtility` (`LoadPrefabContents`, `SaveAsPrefabAsset`, `UnloadPrefabContents`) and `SerializedObject`. Otherwise use the MCP's asset tools.
- **Reading is fine:** you can read their YAML as text.
- **Why:** editing them by hand desynchronises the asset database and breaks GUID references, in ways that surface far from the cause. If the tools are broken, see "When the tooling is missing or broken".

## Searching through the MCP
- **`Unity_Grep` takes a directory, not a file.** Pointed at a file, it reports "No matches found", which reads like the code being absent.
- **`Unity_Grep` doesn't search `.meta` files.**
- **Plan mode** asks the user to approve every MCP call, so plan with the built-in tools and the CLI.

## Sharing the editor
The editor runs one command at a time, and contention shows up as spurious timeouts.
- At most one agent talks to the editor at once. Parallel fan-out agents get no editor access.
- A subagent that does use the editor sticks to pure reads: `AssetDatabase` lookups, hierarchy walks, `console`, `editor_status`.
- Some calls write even though they read like reads: a scene load, a Selection change, `ExecuteMenuItem`, and a `SetDirty` or save. Keep subagents away from them.
- Never give a subagent the editor while the main session is compiling or running tests.

## Development players
A development standalone build can run the same command server, so an agent can drive a built player as it drives the editor, for example as a second network peer.
1. **Turn on** Project Settings › Pipeline › Runtime › `enableInBuilds`, with `set_runtime_pipeline_settings --settings '{"enableInBuilds":true}' --confirm true`. It's stored in `ProjectSettings/Packages/com.unity.pipeline/RuntimePipelineConfig.json`.
2. **Build** outside play mode, as a background command that polls `build_status`:
   ```bash
   unity command build --target StandaloneOSX --outputPath <path>.app --options '["Development","DetailedBuildReport"]' --confirm true
   ```
   - Supplying `options` drops the default `DetailedBuildReport`, so list it.
   - `build_status`'s `data.result` is a JSON string, so parse it twice. Don't recurse on `result`: the build report inside has its own `result` key (`Succeeded`).
3. **Launch** it. On macOS, `open -g -n <app> --args …` keeps it from taking focus from the user. It's ready when `unity command --runtime-path <path> runtime_status` succeeds.
4. **Drive it** with `unity command --runtime-path <path> <command>`. On macOS the path is the `.app` bundle; elsewhere it's the folder next to the executable. `unity command --runtime-path <path>` lists what the player exposes; `quit` closes it.

**What's different in a player:**
- **`eval` can't name the project's own types.** In a player it only references assemblies named `UnityEngine*`, `Assembly-CSharp`, `netstandard`, `mscorlib`, `System.*` or `Unity.Pipeline*`. Types in the project's asmdefs, and in packages such as TextMeshPro, fail with CS0246. Reach them by reflection, finding each type through `AppDomain.CurrentDomain.GetAssemblies()`, or write a command.
- **A `[CliCommand]` static method compiles with the project**, so it uses the project's types directly. A player finds it by reflection over its loaded assemblies, and the editor finds it after a recompile.
  - The attribute lives in `Unity.Pipeline`, which only compiles for the editor and development builds. Put commands in an assembly constrained to `UNITY_EDITOR || DEVELOPMENT_BUILD`.
  - Leave `MainThreadRequired` on for anything that touches Unity objects.
  - Commands answer in tens of milliseconds, where `eval` compiles every call. But changing a command means rebuilding the player, so `eval` stays the tool for one-off probes.
- **There's no `EditorApplication.update`.** For per-frame sampling, add a lambda to `Application.onBeforeRender` from `eval`; that works in editor play mode too. Stamp each row with wall-clock time, so files from two processes line up.
- **Screenshots:** `ScreenCapture.CaptureScreenshot(path)` from `eval`.
- **Main-thread commands run from the player's `Update`.** So a player that pauses when it loses focus stops answering. Check Player Settings › Run In Background.

**What `enableInBuilds` leaves around:**
- **Build folders:** each build bakes the settings into `Assets/Settings/Pipeline/Resources/`. It deletes the baked assets afterwards, but leaves the folders and their `.meta` files. A project that doesn't use that folder itself can ignore `/Assets/Settings/` and `/Assets/Settings.meta`.
- **A port file in the project:** editor play mode runs the runtime server too, and writes `.unity-pipeline-runtime-port` at the project root while it plays. Ignore it.

**Release builds leave the server out entirely.** The Pipeline's runtime assemblies are constrained to `UNITY_EDITOR || DEVELOPMENT_BUILD || ENABLE_RUNTIME_PIPELINE`. To confirm a release build lacks some code:
- Check the build's `Managed` folder and `ScriptingAssemblies.json`.
- Search binaries for a string literal as UTF-16, the way .NET stores it; a plain `grep` misses it.
