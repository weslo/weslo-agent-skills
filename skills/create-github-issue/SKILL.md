---
name: create-github-issue
description: Front of the GitHub issue workflow — turn something the user wants done into a GitHub issue that /address-github-issue can later pick up cold. Check it is not already filed, write a short plain-language body with emoji-headed sections and real links to issues, files and docs, then set labels from the project's own, assign the user, set a milestone only when one clearly fits (asking when it is unclear), and add the parent, sub-issue and blocking relationships that clearly exist. Use this whenever the user asks to file, open, create, log or write up an issue, bug, ticket or task ("make an issue for this", "file a bug", "track this in GitHub"), in this repository or another one they name. Companion to /address-github-issue (doing the work) and /complete-github-issue (merging). Creating the issue is the whole job; it does not start the work.
---

# Creating a GitHub issue

The front of the issue workflow. This skill writes the issue, `/address-github-issue` takes it to
an open PR, and `/complete-github-issue` merges it. **Anything the user says in the moment
overrides what is written here** — another repository, a different layout, someone else as
assignee, no labels. This file is the fallback for everything they did not specify.

Asking for an issue is the request to create it. Do not stop to show a draft unless the user asked
to see one first, and do not start the work itself; that is `/address-github-issue`'s job, when
the user runs it.

**Ask only where this file says to.** Raise a possible duplicate as soon as you find it, since it
decides whether to write anything. Gather every other question for the run, across all the issues
you are filing, into one `AskUserQuestion` call once everything else is ready, or one message in
chat where the tool is not available.

## 1. Pin down the repository and its conventions

- The repository is the current one unless the user names another. For another one, set
  `GH_REPO=<owner>/<repo>` on every `gh` call; unlike `-R`, it also fills the `{owner}` and
  `{repo}` placeholders in `gh api`. With no current repository and none named, ask.

  ```bash
  gh repo view --json nameWithOwner,visibility,defaultBranchRef,hasIssuesEnabled,isInOrganization
  ```

- Read what the project says about issues before using the defaults here: `AGENTS.md`,
  `CLAUDE.md`, `CONTRIBUTING.md`, and any templates in `.github/ISSUE_TEMPLATE/`. A template's
  sections and required fields win over this file's layout. Existing issues do not set the layout,
  but they do show how the project labels work and groups it into milestones.
- Gather what the later sections choose from, in one go:

  ```bash
  gh label list --limit 200 --json name,description
  gh api 'repos/{owner}/{repo}/milestones?state=open' --jq '.[] | {title, description, due_on}'
  gh issue list --state open --limit 200 --json number,title,labels,milestone
  ```

## 2. Check it is not already filed

Scan the open issues you just listed, then search everything, PRs included, since work can be
under way or settled without an issue:

```bash
gh issue list --state all --search "<two or three key words>" --json number,title,state,url
gh pr list --state all --search "<two or three key words>" --json number,title,state,url
```

- **An open issue or PR already covers it:** stop and point to it. Ask whether to add to it (a
  comment or an edit) or to file a new one anyway.
- **A closed issue covered it:** read why it closed, including the PR that closed it
  (`gh issue view <N> --json stateReason,closedByPullRequestsReferences`), whose description often
  holds what was found and what was left unchecked. If it was fixed and the problem is back, or the
  fix left a gap, file a new issue and mention the old one and its PR under 🧭 Context. If the idea
  was turned down, say so before filing.

## 3. Work out what the issue has to say

Write for someone who starts cold. Usually that is a later agent session running
`/address-github-issue`, which sees the issue and the code but not this conversation. The issue's
job is to carry what would otherwise be lost:

- what should change and why, in the user's terms;
- decisions already made and the reasons for them, and options already ruled out;
- limits on the work, and what has to keep working;
- how to tell it is done.

Look at the code enough to link the right files and to describe how things work today. Check what
you state as fact about the code, and say when something is inferred rather than checked. Do not
invent requirements to fill gaps: put a real unknown under ❓ Open questions, and leave out what
the user did not ask for. Something next door that the user did not mention — a similar spot
elsewhere, an obvious extension — is not yours to rule in or out: mention it when you report back.

**For a bug,** how to make it happen, on what setup, and what happened are facts only the user
has. When they are missing and the code cannot answer them, ask. If the user does not know, file
anyway and list what is missing under ❓ Open questions.

**One issue is one PR's worth of work.**

- **Separate requests in one message** become separate issues, each going through sections 2 to 7,
  with no parent tying them together.
- **One request holding pieces that can ship separately** becomes a parent issue with a sub-issue
  for each piece (section 6). Keep it to one issue when the user asked for one.
- Say in chat how you split the work.

## 4. Write the title and body

**Title:** what changes, in plain words, starting with a verb — *Add a dark theme to the settings
page*, *Fix saving when the file name has a slash*. Keep it under about 70 characters, and skip
prefixes like `[Bug]`; labels carry the type. `/address-github-issue` names its session after the
title, so a short one reads better there too.

**Body:** open with one or two sentences, with no header, that add to the title: why the change
matters, or what goes wrong. Leave the why out when nobody gave one and it is not plain, rather
than inventing it. Then add only the sections that have something to say, in this order and with
these headers, so every issue reads the same way:

| Header | What goes in it |
|---|---|
| `## 🐛 What happens` | Bugs only: steps to reproduce, what was expected, what happened instead, and where (version, platform). |
| `## 🧭 Context` | How things work today, with links. Related issues, and why a parent or blocker matters when that is not obvious. Only what someone starting cold needs. |
| `## 🛠️ Change` | What to change, the decisions already made and why, and the limits on the work. Say what, not how, unless the how was decided. |
| `## ✅ Done when` | Results someone can check, including what has to keep working. |
| `## 🚫 Out of scope` | What the user ruled out, or what was decided against, that a reader might assume is included. |
| `## ❓ Open questions` | What the work still has to settle, with what is known so far. |

A small change may need nothing beyond the opening sentences and ✅ Done when.

**Style:**

- Plain, direct words. No jargon. No acronyms or abbreviations unless they are what the reader
  will see on screen or search for, and then spell them out the first time.
- Short sentences. Lists where the items are parallel; when an item needs more than a line, lead
  with its point in bold.
- Backticks for code, file names, commands and settings. Fenced blocks for error output, trimmed
  to the lines that matter, and `<details>` around anything long. Attach a screenshot the user
  gave you with `--attach`.
- Plain bullets in ✅ Done when, not checkboxes: nobody ticks them, and the merge closes the issue
  anyway.
- Say each thing once. No restating the title, no closing summary, no filler like "This issue
  aims to…".
- In a public repository the issue is public. Leave out secrets, paths on the user's machine, and
  personal details the user did not ask to include.

Write the body to a file in the scratchpad with the Write tool, not with an unquoted heredoc:
issue bodies are full of backticks, which the shell runs as commands without any error.

## 5. Link everything that has a link

- **Issues and PRs:** `#123` in the same repository, `owner/repo#123` in another. GitHub turns
  both into links. To mention another issue filed in the same run, create that one first and use
  the number it gets.
- **Files:** link to the file on the default branch,
  `https://github.com/<owner>/<repo>/blob/<default-branch>/<path>`, so the link follows the file
  as it changes. Link a Markdown file's section by its heading, as in `README.md#install`.
- **Specific lines:** link to a commit rather than a branch, so the lines do not drift:
  `https://github.com/<owner>/<repo>/blob/<sha>/<path>#L10-L24`, adding `?plain=1` before the `#`
  for a Markdown file so the link opens on those lines rather than the rendered page. Take the
  commit from the remote, and read the line numbers from that commit, not from your working tree,
  which may differ:

  ```bash
  gh api 'repos/{owner}/{repo}/commits/<default-branch>' --jq .sha
  git fetch origin && git show <sha>:<path>
  # for a repository that is not checked out here:
  gh api 'repos/{owner}/{repo}/contents/<path>?ref=<sha>' -H 'Accept: application/vnd.github.raw'
  ```

  In the same repository's issues, GitHub shows a bare link like this as an embedded code snippet;
  inside link text, or in another repository's issues, it stays a plain link. Put a bare one on a
  line of its own, since the snippet splits any sentence it sits in. One or two snippets suit a
  short issue; give any further lines as link text.
- **Commits:** the bare commit hash; GitHub links it.
- **Anything else** — docs, a discussion, a design file: a markdown link whose text says what it
  is, never "here".
- **Code not on the default branch:** link it at a pushed commit. Code that is not pushed at all
  has no link; name its path in backticks and say it is not pushed yet.
- **People:** `@login` notifies them. Use it only when the user wants that person to see the
  issue.

## 6. Set labels, assignee, milestone and relationships

**Labels.** Use the project's existing labels, and do not create new ones unless asked. Choose by
name and description, and label the way similar existing issues are labelled: usually the one
label for the kind of work (`bug`, `enhancement`, `documentation`), plus any label for the area
that clearly applies. Leave off labels about triage or inviting help — `duplicate`, `invalid`,
`wontfix`, `question`, `good first issue`, `help wanted` — unless the user asks. With no good fit,
use no label.

Repositories owned by an organization (`isInOrganization` in section 1) can also define issue
types. When it is one, list them, and set one with `--type` when it clearly fits; an empty or
`null` list means there are none:

```bash
gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") { issueTypes(first: 25) { nodes { name description } } } }'
```

**Assignee.** The user who asked, with `--assignee @me`, which is the account `gh` is signed in
as. `gh api user --jq .login` names that account. If it fails, as it does under a GitHub App
token, or names a bot (a login ending in `[bot]`) or an account that is not the user's, assign the
user's own login instead, asking if you do not know it. Assign someone else when the user says
so.

**Milestone.**

- **One open milestone clearly fits:** set it. It clearly fits when the user named it, when its
  title or description covers this work, or when this issue's parent, or an issue it blocks, is in
  that milestone.
- **None could fit** — there are no open milestones, or none is about this kind of work: leave it
  empty without asking.
- **It is unclear** — more than one could fit, or one might fit but nothing ties this work to it:
  ask, header `Milestone`, with one option per candidate showing its description and due date (the
  day, not the timestamp), and *No milestone* last.

**Relationships.** Add only the ones that clearly exist, and mention looser connections under
🧭 Context instead:

- **Parent:** this issue is one piece of a bigger issue that tracks the whole: `--parent <N>`.
- **Blocked by:** this work cannot start, or cannot finish, until another open issue is done:
  `--blocked-by <N>`.
- **Blocking:** another open issue is waiting on this one: `--blocking <N>`.

Each flag takes issue numbers or URLs, comma-separated, and URLs work across repositories. Do not
relate a new issue to a closed one; mention it under 🧭 Context. When filing several issues,
create them in dependency order — the parent first, blockers before what they block — so every
number exists when it is used.

## 7. Create it and check it

```bash
gh issue create --title "<title>" --body-file <body.md> \
  --assignee @me --label "<label>,<label>" --milestone "<milestone>" \
  --parent <N> --blocked-by <N> --blocking <N>
```

Leave out each flag with nothing to set. An older `gh` does not know `--parent`, `--blocked-by`
or `--blocking`, and it rejects an unknown flag before creating anything. If that happens, create
the issue without them and tell the user which relationships still need adding, and that updating
`gh` adds the flags.

Then check that everything landed, rather than trusting the exit code:

```bash
gh issue view <N> --json url,labels,assignees,milestone,parent,blockedBy,blocking \
  --jq '{url, labels: [.labels[].name], assignees: [.assignees[].login], milestone: .milestone.title,
         parent: .parent.number, blockedBy: [.blockedBy.nodes[].number], blocking: [.blocking.nodes[].number]}'
```

Fix anything missing with `gh issue edit <N>`, which takes `--add-label`, `--add-assignee`,
`--milestone`, `--parent`, `--add-blocked-by` and `--add-blocking`.

## Reporting back

Lead with the link to each issue filed. Then one line per issue on what was set — labels,
assignee, milestone, or why there is none, and relationships — and anything you could not set or
check, a near-duplicate you found, how you split the work, and anything next door the user did not
mention. Do not repeat the bodies; they are one click away.
