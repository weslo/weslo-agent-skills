---
name: complete-github-issue
description: Bookend to /address-github-issue — the merge-and-cleanup half. Squash-merge an approved PR with a real squash message, confirm the linked issue closed, resync local main to the merged commit, delete the merged branch locally and remotely, and verify every one of those outcomes rather than assuming them. Use this whenever the user says the PR is ready to go ("merge it", "merge the PR, close the issue, get local on main", "wrap this up", "ship it"), whether or not the PR was opened in this session. Never use it on the user's behalf before they ask — merging is outward-facing and awkward to undo.
---

# Completing a GitHub issue

The closing half of the issue workflow. `/address-github-issue` takes an issue to an open PR;
this skill takes an approved PR to a merged, closed, cleaned-up end state. **Anything the user
says in the moment overrides what is written here** — a merge commit instead of a squash,
keeping the branch, leaving the issue open — but the fallback is the sequence below, run in
full without re-asking once the user has said to merge.

## 0. Only when asked

Do not merge on your own initiative, and do not treat approval of a *plan* or a *review* as
permission to merge. The trigger is the user saying, in this conversation, that this PR should
be merged. Once they have, run the whole sequence — merge, issue check, resync, branch cleanup —
without asking again at each step; that is what they asked for.

## 1. Know what you are merging

```bash
gh pr view <N> --json number,title,state,mergeable,mergeStateStatus,headRefName,baseRefName,body
```

- `state` must be `OPEN`, `mergeable` `MERGEABLE`, `mergeStateStatus` `CLEAN` (or `UNSTABLE`
  only if the user has said failing or pending checks are acceptable). Anything else — `DIRTY`,
  `BEHIND`, `BLOCKED` — is a reason to stop and say so, not to force.
- Read the body for `Closes #<issue>`. If it is missing or malformed, the issue will not close
  on merge; either fix the body first (`gh pr edit <N> --body-file ...`) or plan to close the
  issue explicitly in step 4.
- Note `headRefName`. You will delete that branch locally, and you cannot delete a branch you are
  standing on.
- If the working tree has uncommitted changes, decide what they are before proceeding. Changes
  that belong to the PR must be committed and pushed first; churn (regenerated caches, IDE
  settings, rewritten project settings) stays out and gets mentioned in the report.
- If the local branch is behind the remote (someone edited on GitHub), `git fetch origin` and
  rebase or fast-forward before pushing anything; never force-push over it.

## 2. Write a real squash message, then merge

The squash message becomes the permanent history entry for the whole branch. Do not let `gh`
concatenate the commit subjects. Write it to a file first:

- **Subject**: the PR title with the PR number appended, `<title> (#<N>)`.
- **Body**: what changed and why in prose, then how it was verified, then anything a future
  reader should know was deliberate or left undone. Summarize the branch, do not list its
  commits.
- Include `Closes #<issue>` on its own line so the issue closes on merge even if the PR body
  was edited.
- End with the attribution trailers this session uses for commits.

```bash
gh pr merge <N> --squash --delete-branch \
  --subject "<title> (#<N>)" --body-file <squash-message-file>
```

`--delete-branch` removes the remote branch. When you are standing on the head branch locally,
`gh` may switch you to the default branch or leave the local branch in place; step 3 handles
both, so do not fight it here.

## 3. Resync local and remove the merged branch

```bash
git checkout main
git pull --ff-only origin main
git fetch --prune origin
git branch -D <headRefName>
```

- `--ff-only` is deliberate: if it refuses, local main has diverged from origin, which is a
  situation to report, not to resolve with a merge commit on main.
- `git branch -D` (capital) is required because a squash merge leaves the local branch's commits
  unreachable from main, so `-d` refuses. If the branch is already gone, that is fine.
- If the remote branch still exists (auto-delete disabled, or `--delete-branch` was skipped),
  remove it explicitly: `git push origin --delete <headRefName>`.

## 4. Verify all four outcomes

Do not report success from the absence of errors. Check each:

```bash
gh pr view <N> --json state,mergedAt,mergeCommit --jq '"\(.state) \(.mergedAt) \(.mergeCommit.oid)"'   # MERGED
gh issue view <issue> --json state,closedAt --jq '"\(.state) \(.closedAt)"'                       # CLOSED
git branch -a | grep <headRefName> || echo "branch gone locally and remotely"
git log --oneline -1                                                                               # main carries the squash commit
git status --short                                                                                 # clean, or only known churn
```

If the issue is still `OPEN`, close it yourself with a comment pointing at the PR:

```bash
gh issue close <issue> --comment "Fixed in #<N>."
```

## 5. Mark the issue's session done

`/address-github-issue` keeps a status emoji in front of the name of the session that worked the
issue: `<status> Address Issue #<issue>: <issue title>`. Once step 4 shows the PR merged and the
issue closed, swap that emoji for ✅, whichever session ran the merge, so the session list shows
the issue is finished. Only the prefix changes; the text after it stays.

- Find the session with the desktop app's `mcp__ccd_session_mgmt__list_sessions`, with `limit`
  raised past its default of 20, since that session may have been idle for days. Match a title
  that, after the emoji, starts with `Address Issue #<issue>:` — the colon keeps `#12` from
  matching `#123` — on a session whose `cwd` is this repository or a path `git worktree list`
  prints. The list leaves out the current session, so check this session's own title too, with
  `mcp__ccd_session_mgmt__get_session` and `session_id: "self"`.
- Rename each match with `mcp__ccd_session_mgmt__set_session_title`, passing its `sessionId`, or
  `"self"` for this session. Load these tools through ToolSearch first if they are deferred.
- If nothing matches, the tools are not available — a terminal session has none — or the user
  declines a rename, carry on.
- In plan mode, wait until the plan is approved before any of this: plan mode asks the user to
  approve every MCP tool call, these three included, whatever the allow rules say.

## 6. Tidy anything the work left behind

- Local branches from abandoned attempts at the same issue: list them (`git branch --list`) and
  delete any the user does not want, asking only if unsure whether one holds unmerged work.
- Untracked files the tooling created during verification (build outputs inside the repo, logs,
  scratch scripts written into the project by mistake): remove the ones that are yours; leave
  anything that could be the user's.
- Anything the PR body promised as "pending" or "user-verified" that has now been done can be
  reflected in the issue or PR with a short comment, if the user cares to have the record.

## Reporting back

Lead with the end state, verified: the PR is merged (squash commit hash), the issue is closed,
local main is at that commit, and the branch is gone locally and remotely. Then anything that
did not go to plan — the issue needed closing by hand, the remote branch had to be deleted
explicitly, churn left in the working tree, a divergence you did not resolve. Keep it to what
the user cannot see for themselves.
