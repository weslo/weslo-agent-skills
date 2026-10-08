---
name: address-github-issue
description: End-to-end workflow for taking a GitHub issue from investigation to merged PR — branch off latest main, investigate before committing to an approach, verify what a user would actually notice, open a PR, and (only when explicitly asked) squash-merge, close the issue, delete the branch, and resync local. Use this whenever the user points at a GitHub issue and wants it worked on ("address issue #42", "take a look at #7", "let's knock out this issue", or a pasted issue URL), and again later when they ask to merge or wrap up the PR that came from it. Also use it when the work is issue-shaped — a tracked bug or feature to be implemented and shipped as a PR — even if the user never says the word "issue".
---

# Addressing a GitHub issue

This is the default shape of the work. **Anything the user says in the moment overrides
what is written here** — if they ask for a different branch name, a merge commit instead of
a squash, no PR at all, or want to skip straight to implementation, do that instead. This
file is the fallback for everything they did not specify.

## Keep the session title current

As soon as section 1 has given you the issue's title, name the session after the issue, and
keep a status emoji in front of the name while you work, so the session list shows where
each issue stands without opening it:

```text
<status> Address Issue #<N>: <issue title>
```

- 📝 **Planning** — understanding, investigating, and planning: sections 1 to 4.
- 🛠️ **Working** — implementing, verifying, opening the PR, and working through review
  feedback: sections 5 to 8.
- 👋 **Needs input or ready for review** — whenever the next move is the user's: a question
  or decision put to them, a blocker only they can clear, the PR opened, or a round of
  review feedback addressed.
- ⏳ **Waiting on CI** — `/complete-github-issue` sets this while it waits for the PR's checks
  before merging.
- ✅ **Merged and closed** — `/complete-github-issue` sets this once the PR is merged and the
  issue closed, from whichever session it runs in.

Only the prefix changes: keep the text exactly as you first set it, with the issue title as
GitHub has it, and rename only when the status actually changes. Set 👋 before the message
that hands over, because nothing runs after it; when the user replies, switch to the prefix
for the work that follows.

Rename with the desktop app's `mcp__ccd_session_mgmt__set_session_title` tool and
`session_id: "self"`, loading the tool through ToolSearch first if it is deferred. If the
tool is not available — a terminal session has none — carry on without it. If the user
declines a rename, stop renaming for the rest of the session; every later rename would ask
them again.

While plan mode is active, do not rename at all. Plan mode asks the user to approve every MCP
tool call, renames included, whatever the allow rules say. Name the session right after the
plan is approved instead, with the prefix for the work that follows.

## 1. Understand the issue before touching anything

Read the issue itself, not just its title:

```bash
gh issue view <N> --json title,body,state,labels,comments
```

Titles compress badly. The body and comments usually carry the actual constraint, and a
closed-as-duplicate or a linked PR can mean the work is already done or already decided.
If the issue is a one-liner with no body — common for personal projects — say so and work
from what the user tells you rather than inventing requirements to fill the gap.

Now name the session, as *Keep the session title current* above describes. In plan mode, wait
until the plan is approved.

## 2. Branch from latest main, not from wherever you are

```bash
git checkout main
git fetch origin
git pull --ff-only origin main
git checkout -b <descriptive-kebab-branch>
```

Branching off a stale local main is a quiet way to create a painful merge later. Do the
fetch even when you believe you are current — believing is cheap and wrong often enough.

If a branch for this work already exists from an earlier session, check whether it still
has commits worth keeping before deleting or rebasing it.

## 3. Investigate through authoritative sources

Find out how things actually are before deciding what to change. Two habits matter:

**Prefer the system's own view over textual inference.** Querying the thing that owns the
truth — an API, a database, an editor's asset database, a type system — beats grepping for
patterns and reasoning about what they imply. Text search tells you where a string appears;
it does not tell you what is wired to what. When a tool mangles or truncates output, treat
its content as unreliable and confirm through another channel.

**Re-validate inherited facts before building on them.** Findings carried over from an
earlier session, a previous investigation, or a channel that was degraded at the time are
hypotheses, not facts. Confirm the load-bearing ones. A plan resting on five inferred
claims fails in whichever one was wrong, and it fails late.

Check the project's own agent guidance (`AGENTS.md`, `CLAUDE.md`, or similar) for required
tools and workflows before defaulting to generic ones.

**Bring the project's tooling up in automation mode before you start.** A tool a human
opened interactively behaves differently from one launched to be driven, and the difference
shows up as flakiness rather than as an error message. When the project's agent guidance
says how to launch a tool for automation — a flag, a headless mode, a dedicated command — do
that at the start rather than after the first stall; retrying or refocusing a tool launched
the other way rarely fixes it. If commands start timing out, check how the tool was launched
before diagnosing anything else. Ask before closing one the user is working in; otherwise
relaunch it the way the guidance says.

**A timed-out call may still have run to completion.** The timeout describes the reply, not
the work. Check side effects — read the file it was supposed to write, run `git status` —
before retrying, or you will do the work twice, and in the worst case a half-applied retry
silently corrupts a result you then reason from.

## 4. Plan when the work is big enough to warrant it

For anything beyond a small, obvious change, write down the approach and the open questions
before implementing. Put genuine decisions to the user — the ones where different answers
produce materially different work — rather than picking silently and hoping. Recording the
decisions and their rationale (in the issue body, or a comment) pays for itself when the PR
gets reviewed and when someone asks "why did we do it this way" months later.

Do not block on questions you can answer yourself, and do not stall the whole task waiting
for an answer to something that only affects part of it.

## 5. Implement the requested scope

Stay inside the issue. Things you notice along the way that are real but out of scope
belong in a note or a follow-up issue, not in this PR — a diff that quietly grows is harder
to review and harder to revert.

If you deviate from an agreed plan because reality demanded it, that is often correct, but
say so explicitly rather than folding it in silently.

## 6. Verify what a user would actually notice

This is where issue work most often goes wrong, so spend real effort here.

**Test the property, not a proxy for it.** Before accepting a check, ask: *if this feature
were broken in the way the user would complain about, would this test fail?* A measurement
can be precise, quantitative, and completely beside the point. Confirming that a mechanism
is wired correctly is not the same as confirming the behavior works.

**Test across time and states, not at one instant.** A single-moment snapshot can prove two
configurations differ while missing that neither one behaves correctly as things play out.
If the change affects something continuous or stateful, sample it across its range.

**Exercise the paths you did not change.** Regressions cluster in the cases you were not
thinking about — the idle case, the empty case, the default branch, the other user, the
thing that was previously handled implicitly. If the change alters a shared mechanism, the
untouched callers of that mechanism are the ones to check.

**Run it the way the project runs it.** Follow the project's own launch/test flow rather
than improvising one, and confirm the end state instead of assuming the command worked.

Be honest about coverage. State plainly what you verified, and name what you did not —
"not tested with a second client" is useful to a reviewer; silence implies a confidence you
did not earn.

## 7. Open the PR

Commit in logical units with messages that explain *why*, then:

```bash
git status --short          # confirm only intended files are staged
git push -u origin <branch>
gh pr create --base main --title "<what changed>" --body-file <file>
```

Check `git status` before staging and stage paths explicitly. Editor- or tool-generated
churn in unrelated files (regenerated caches, atlases, lockfiles, formatting-only diffs)
should stay out of the PR — revert it or leave it uncommitted, and mention it so the user
knows it exists.

Put `Closes #<N>` in the PR body so the issue closes automatically on merge.

A good PR body states what changed and why, calls out anything surprising found along the
way, summarizes how it was verified, and flags what a reviewer should look at hardest —
especially any pre-existing behavior the change touches.

## 8. Handle review feedback

When the user reports a problem, find the actual cause before proposing a fix. If two
symptoms appear at once, check whether they share a root cause — they often do, and fixing
them separately produces two partial fixes.

When a regression traces back to a flaw in how you verified the work, fix the verification
too, and say what the gap was. That is more useful to the user than an apology.

**Close the loop on the thread, not just in chat.** Review comments live on the PR, and a
reviewer coming back to it should be able to see what happened to each one without
reconstructing it from a conversation they were not part of. When you address a comment,
reply on its thread saying what changed and in which commit, then mark the thread resolved:

```bash
# reply to the thread (the id is the first comment's id, from `gh api .../pulls/<N>/comments`)
gh api repos/<owner>/<repo>/pulls/<N>/comments/<comment-id>/replies -f body="<what changed, and where>"

# resolve it (thread ids come from the GraphQL reviewThreads query)
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "<thread-id>"}) { thread { isResolved } } }'
```

Do this as each comment is addressed rather than in a batch at the end, or the record drifts
from the branch and the threads pile up.

Resolve only what is actually done. A comment you answered with reasoning rather than a
change, or one whose fix landed somewhere different from what was discussed, needs the reply
to say so plainly and is often better left open for the reviewer to close. Say in the reply
when the result differs from what was agreed, and why — that is exactly what a reviewer
would otherwise have to discover by reading the diff.

Keep the PR description current as the branch evolves. A stale PR body actively misleads a
reviewer, and it will be stale by the end of a long review cycle if you never revisit it.

## 9. Merge and clean up — only when asked

**Do not merge on your own initiative.** Merging is outward-facing and awkward to undo;
wait for the user to ask. When they do, run `/complete-github-issue`: it waits for CI,
merges, confirms the issue closed, resyncs local main, removes the branch, and keeps this
session's status current throughout.

## Reporting back

Lead with the outcome and the things the user cannot see for themselves: what changed, what
surprised you, what you verified, and what is still uncovered. Corrections to your own
earlier claims belong here too, stated plainly and briefly — a reviewer acting on a wrong
fact you stated earlier is a worse outcome than an awkward correction.
