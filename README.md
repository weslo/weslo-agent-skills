# weslo-agent-skills

Agent skills I use across projects, one per `skills/<name>/SKILL.md`.

- `address-github-issue` takes a GitHub issue from investigation to an open PR, and merges it when asked.
- `complete-github-issue` waits for CI, squash-merges an approved PR once it passes, confirms its issue closed, resyncs main and deletes the branch. A CI failure stops it with a fix or a diagnosis for you.
- `review-github-pr` reviews a PR with inline comments, then confirms fixes and resolves threads on later passes.
- `unity-use` is how to drive a Unity editor from an agent session: automation launch, the 5 s command limit, domain reloads, waiting without polling, `eval` snippets, and the files only the editor may change.

## Install

Clone this repo, then run its install script. It links each skill into `~/.claude/skills`, where Claude Code loads it in every project:

```bash
./install.sh
```

The skills are linked, not copied, so edits made while working land in this checkout. Commit and push them here, and `git pull` on other machines. Run `install.sh` again after adding a skill.

A session that started before `~/.claude/skills` existed needs `/reload-skills` to see them; later sessions load them on their own.

Project-specific details, such as how to launch a project's tools or what to check in its reviews, belong in that project's own agent guidance (`AGENTS.md`), which these skills read.
