---
name: review-github-pr
description: Reviewer side of the GitHub PR workflow — review a pull request for real bugs, post each problem on the PR itself as an inline review comment on the line that needs work, then give the user a short itemized index in chat; on later passes, check each fix on the PR head, reply where it adds something, and resolve the threads that are actually fixed. Use this whenever the user asks you to review a PR (a number, a URL, or "my PR"), to leave feedback or comments on a PR, or to re-review after pushing fixes ("should be fixed now", "check my fixes and resolve what's done") — even if they never say GitHub. Companion to /address-github-issue (author side) and /complete-github-issue (merging). Not for answering review comments as the PR's author, which is /address-github-issue, and not for a local diff with no PR, which /code-review covers.
---

# Reviewing a GitHub pull request

The reviewer's half of the PR workflow. `/address-github-issue` takes an issue to an open PR and
answers review as its author; `/complete-github-issue` merges it. This skill reviews it: find the
problems worth fixing, leave each one on the PR at the line it concerns, give the user a short
index in chat, and on later passes confirm the fixes and close the threads. **Anything the user
says in the moment overrides what is written here** — a chat-only review, a different depth,
approving rather than commenting. This file is the fallback for everything they did not specify.

Invoking this skill on a PR is the request to comment on that PR. It is not permission to approve,
request changes, merge, or comment anywhere else; ask for those.

## 1. Pin down what you are reviewing

```bash
gh pr view <N> --json number,title,state,author,url,body,baseRefName,headRefName,headRefOid
git fetch origin pull/<N>/head        # works for branches on forks too
gh pr diff <N>                        # the diff under review
git show <headRefOid>:<path>          # a whole file as the PR has it
```

- With no number or URL given, use the current branch's PR (`gh pr view --json number`). If there is
  no PR there is nothing to comment on; say so and offer `/code-review` for the local diff.
- **Name the session after the PR** once you know which one it is, so the session list shows what
  each session is reviewing: `Review PR #<N>: <PR title>`, with the title exactly as GitHub has it.
  Rename it with the desktop app's `mcp__ccd_session_mgmt__set_session_title` tool and
  `session_id: "self"`, loading the tool through ToolSearch first if it is deferred. If the tool is
  not available — a terminal session has none — or the rename is declined, carry on without it.
  In plan mode, rename once the plan is approved instead: plan mode asks the user to approve every
  MCP tool call, the rename included, whatever the allow rules say.
- If the PR is `MERGED` or `CLOSED`, say so before posting anything. New comments on a closed PR are
  rarely read, so offer a follow-up issue for new findings instead. Replying on and resolving
  existing threads is still fine.
- **Review the PR head, not the working tree.** The local checkout can hold changes the PR does not
  have, or lack commits it does. Read files with `git show <headRefOid>:<path>` so what you review is
  what the author and every other reader see.
- Read the PR body for intent and for anything the author asks reviewers to look at hardest.
- Read the existing review threads before starting:
  `${CLAUDE_SKILL_DIR}/scripts/review-threads.sh <N>`. Threads with `"ours": true` came
  from an earlier run; if there are any, this is also a re-review, so work through section 5
  alongside reviewing whatever is new. Read the other threads too, resolved or not, so you do not
  post again what the user, another reviewer or a bot has already raised.

## 2. Find the problems worth fixing

This is `/code-review`'s method: one careful pass over the whole diff, looking for real failure modes
rather than style.

- Read every hunk, then open what it touches: callers of changed functions, other implementations of
  a changed abstraction, subscribers to a changed event, and the data or config files that serialize
  a changed field.
- Hunt for wrong or inverted conditions, off-by-one errors, null dereferences, missing awaits, dropped
  error handling, removed guards or validation, callers broken by a changed signature or contract,
  races and ordering assumptions, and state that is never reset.
- Also look for:
  - Code behind build flags or environment checks. The branch the author ran locally may not be the
    one a release build runs.
  - Static or global state that outlives the scope it was set up for.
  - Code that acts inside another system's event dispatch, where listeners later in the same dispatch
    can still see the state it meant to change.
  - Changes to shared files the PR's purpose does not explain — project settings, lockfiles, package
    manifests, generated files. These are often tool churn; a one-line comment asking whether the
    change is intended is enough.
- Add the project's own review checks from its agent guidance (`AGENTS.md`, `CLAUDE.md`) or its
  contributing docs, when it has them.
- **Confirm third-party behaviour from its source.** Read the dependency's code where the project
  keeps it — a package cache, vendored sources, installed modules — rather than inferring behaviour
  from its docs or names. Reading the source turns hunches into confirmed findings, and just as often
  shows that a suspected problem cannot happen.
- **Every finding needs a concrete failure scenario**: the state or input, what the code then does,
  and what a user or developer sees. If you cannot write one, it is not a finding yet.
- **Try to kill each candidate before posting it**, and drop what does not survive. When a finding
  survives but you could not confirm it — an untested platform, behaviour you inferred — keep it and
  say so in the comment, so the reader knows which claims to check.
- Design comments come second, and only with a reason behind them: a written standard
  (`CONTRIBUTING.md`, `.editorconfig`), a review rule recorded from an earlier PR, or a concrete
  maintenance cost. The kinds that have earned their place on past PRs: a condition or symbol
  repeated where one definition should own it, a concept leaking into a class that should not know
  about it, a name that implies a framework contract the class does not have, a setting kept away
  from its only consumer, an ad-hoc singleton. Keep them few and label them as design.
- Post at most 15 findings, most severe first. Default to findings you are confident in; if the user
  asks for a thorough pass, widen the net and include plausible ones, labelled as such.
- A review is static. Do not build, launch or drive the project for it, and the summary says the
  change was not compiled or run.

## 3. Post the feedback on the PR

Post one review per pass, with every finding as an inline comment.

- **Use the `COMMENT` event.** GitHub rejects `APPROVE` and `REQUEST_CHANGES` on your own PR, and here
  the `gh` account is usually the PR's author; approval is the user's call in any case. Leaving
  `event` out creates a pending review that nobody else can see.
- **Anchor each comment on the line that has to change**, on the new side of the diff
  (`"side": "RIGHT"`). The line must fall inside one of that file's diff hunks. A finding about
  something missing — nothing copies a file the change depends on — anchors on the changed line that
  depends on it. A finding about deleted code uses `"side": "LEFT"` and the old line number. Span
  several lines with `start_line` and `line`. Prefer an inline anchor even for a cross-cutting finding:
  only threads can be resolved later, and a finding in the review body leaves nothing to close.
- **Shape each comment for the author who has to act on it:**

  ```markdown
  **<The defect in one sentence.>** <What the code, or the dependency it calls, actually does, with
  the names in backticks.>

  Scenario: <the state or input>, then <what happens>, so <what a user or developer sees>.

  <A suggested fix in a sentence or two, if one is clear. Any limit on your confidence, such as
  "I haven't tested this on macOS.">

  <!-- review-github-pr -->
  ```

- **End every comment with the `<!-- review-github-pr -->` marker.** GitHub does not render it. A later
  session has no access to this conversation, and every comment posted through `gh` carries the
  user's own login, so the marker is the only way to tell this skill's threads from the user's
  hand-written comments, other reviewers' and bots'.
- **Build the payload without the shell touching it.** Comment bodies are full of backticks and `$`,
  and an unquoted heredoc runs the backticks as commands, which mangles the text without any error.
  Write the JSON to the scratchpad with the Write tool, or use a quoted `<<'EOF'` heredoc:

  ```json
  {
    "commit_id": "<headRefOid>",
    "event": "COMMENT",
    "body": "<n> findings from a static review of <short sha>; not compiled or run.\n\n<!-- review-github-pr -->",
    "comments": [
      { "path": "src/net/session.ts", "line": 132, "side": "RIGHT", "body": "...\n\n<!-- review-github-pr -->" }
    ]
  }
  ```

  ```bash
  gh api repos/{owner}/{repo}/pulls/<N>/reviews --method POST --input <payload.json> --jq .html_url
  ```

  `gh` fills `{owner}` and `{repo}` in from the current repository.
- A 422 response means an anchor is not in the diff. The review is created all or nothing, so fix the
  anchor and send it again; nothing was half-posted.
- Re-read `headRefOid` just before posting. If the head moved while you were reviewing, check that the
  new commits leave your anchors and findings intact.
- If there are no findings, post nothing and say so in chat.

## 4. Summarize in chat

The PR holds the detail; the chat gets an index the user can act from. Give one line per finding, in
the order posted, then the limits of the review:

```markdown
Posted 3 comments on #42 ([review](<html_url>)):
- [session.ts:132](src/net/session.ts:132) — calling `connect()` twice throws: the transport setter rejects any assignment mid-session.
- [lobby.ts:271](src/net/lobby.ts:271) — the member-limit kick runs inside the join event's dispatch, so later listeners still see the kicked member.
- [package.ts:55](scripts/package.ts:55) — nothing copies `app.config.json` beside the build, so the packaged app cannot start outside the dev environment.

Static review — not compiled or run.
```

Do not restate the scenarios or the suggested fixes; they are one click away.

## 5. Re-review: confirm fixes, reply, resolve

This runs when the user says fixes are in ("pushed", "should be fixed", "re-review and resolve"), or
when section 1 finds this skill's threads from an earlier pass.

1. **List the threads** with `${CLAUDE_SKILL_DIR}/scripts/review-threads.sh <N>`. Each line
   carries the thread's GraphQL id (`thread`), its first comment's REST id (`comment`),
   `resolved`, `outdated`, `path`, `line`, `reviewedCommit`, `ours`, the original `body`, and every
   reply. Work on the `"ours": true` threads. Threads from the user, other reviewers, or bots are
   theirs to close: report their state, and resolve one only if the user asks. A thread goes outdated
   when the code under it changes and then has no current line, so match threads by `comment`, never
   by line.

2. **Make sure the fixes are on the PR.** Compare `headRefOid` with the `reviewedCommit` on your
   threads. If the head has not moved, the fixes are not pushed. Look for them locally
   (`git status --short`, `git log --oneline origin/<headRefName>..HEAD`). You can read local fixes and
   give early feedback on them, but resolve nothing: a resolved thread tells the next reader the PR
   contains a fix it does not. Say the fixes are not pushed yet, and resolve once they are.

3. **Read what changed since your review**: `git diff <reviewedCommit> <headRefOid>`. If the branch was
   rebased or force-pushed, `reviewedCommit` is no longer an ancestor of the head
   (`git merge-base --is-ancestor` says so); review the whole diff again instead. Hold the fix to the
   section 2 standard, because fixes bring bugs of their own. Read every reply on each thread too: an
   author who pushes back with reasoning deserves an answer on the merits, and if they are right, say
   so and resolve.

4. **Decide each thread:**
   - Fixed: resolve it, replying first if the reply adds something.
   - Partly fixed: reply with what is fixed and what remains, and leave it open.
   - Fixed differently than you suggested: judge the result, not its resemblance to your suggestion.
   - Not fixed: leave it open, and reply only if you have something new to say.
   - Resolved by the author, but the fix does not hold: reply with why and reopen it
     (`unresolveReviewThread`).

5. **Reply when it adds information, then resolve.** A reply is worth posting when it names the commit
   that fixed the problem and the author has not, records something you checked that the next reader
   would otherwise redo (why the fix is race-free, which platforms it now covers), says what is still
   open, or corrects something wrong in your original comment. If the author's own reply already says
   what changed and the fix holds, resolving is enough. Skip thanks and restatements.

   ```bash
   gh api repos/{owner}/{repo}/pulls/<N>/comments/<comment>/replies -F body=@- <<'EOF'
   Fixed in 369a565: `connect()` now refuses while a session is open.
   EOF

   gh api graphql -f id=<thread> \
     -f query='mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }'
   ```

   Reply to and resolve each thread as you finish judging it rather than in a batch at the end.

6. **Post new problems in the fix code as a new review** (section 3), with the same marker. The one
   exception is the original defect surviving the fix, which belongs on its original thread.

7. **Summarize in the same indexed style:**

   ```markdown
   Re-reviewed #42 at c903ccf (3 commits since my review):
   - Resolved — `connect()` twice throws: fixed in 369a565.
   - Resolved — member-limit kick: fixed in fcf187b.
   - Open — `app.config.json`: fixed for Windows and Linux; a macOS app opened from Finder still won't find it (replied with details).
   - Not mine — the Codex bot's `app.config.json` thread is still open.

   No new findings. Static review — not compiled or run.
   ```

## Reporting back

Lead with what was posted or resolved, and link it. Say what you did not verify. If a claim you posted
earlier turns out to be wrong, correct it on its thread and in chat, plainly: a wrong claim left
standing on the PR costs the author more than an awkward correction.
