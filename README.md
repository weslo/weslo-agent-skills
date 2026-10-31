# weslo-agent-skills

Agent skills I use across projects, one per `skills/<name>/SKILL.md`.

- `address-github-issue` takes a GitHub issue from investigation to an open PR, and merges it when asked.
- `blender-use` is how to drive Blender from an agent session, live through the MCP for Blender or headless: launching and quitting it without losing the user's work, saving without losing the file's layout, rebuilding an edit from the committed file, checking with numbers before images, and checking what an export changed. The `blender-*` skills cover the craft.
- `clarify` answers a question about something Claude said in plain language, without jargon, acronyms or shorthand, and does nothing else that turn: no tools, no changes, nothing built or run. Only you can run it, as `/clarify <question>`; on its own, it re-explains Claude's last reply.
- `complete-github-issue` waits for CI, squash-merges an approved PR once it passes, confirms its issue closed, resyncs main and deletes the branch. A CI failure stops it with a fix or a diagnosis for you.
- `create-github-issue` files a GitHub issue that `address-github-issue` can later pick up cold: a short, plain body with links, the project's own labels, you as assignee, a milestone when one clearly fits, and parent, sub-issue and blocking relationships.
- `review-github-pr` reviews a PR with inline comments, then confirms fixes and resolves threads on later passes.
- `technical-review` reviews a whole project's code and architecture for quality, consistency, organization and security, tracked in a GitHub issue or kept in the conversation, then works through your responses to it. Its topics are in `skills/technical-review/review-prompt.md`.
- `unity-use` is how to drive a Unity editor from an agent session: automation launch, the 5 s command limit, domain reloads, waiting without polling, `eval` snippets, the files only the editor may change, and driving development players.

## Install

Clone this repo, then run its install script. It links each skill into `~/.claude/skills`, where Claude Code loads it in every project:

```bash
./install.sh
```

The skills are linked, not copied, so edits made while working land in this checkout. Commit and push them here, and `git pull` on other machines. Run `install.sh` again after adding a skill.

On Windows, run it from Git Bash. Each link is a real symlink when Windows allows one, which takes Developer Mode or an elevated shell, and a directory junction otherwise. A junction needs no special rights, and Claude Code loads skills through it the same way. Git Bash's own `ln -s` can't be used as is: it quietly copies the directory unless told to make a native symlink, and a native symlink fails without those rights.

A session that started before `~/.claude/skills` existed needs `/reload-skills` to see them; later sessions load them on their own.

Project-specific details, such as how to launch a project's tools or what to check in its reviews, belong in that project's own agent guidance (`AGENTS.md`), which these skills read.
