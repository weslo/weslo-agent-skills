---
name: clarify
description: Answer the user's question about something you said, or something in the conversation, in plain language, and do nothing else in that turn — no tools, no changes, nothing built or run; only reasoning over what is already in the conversation. Replaces jargon, acronyms and shorthand with plain words, and untangles terms that may have been used for more than one thing. Run by the user as `/clarify <question>`; with no question, it re-explains your last reply in plain language.
disable-model-invocation: true
argument-hint: "[question]"
---

# Clarify

`/clarify` means the user is asking about something you said, or something in the
conversation, and wants a plain answer before anything else happens. It is the short form of
two things:

1. **This turn is read-only.** No tools, no changes, nothing built or run. Answer from what is
   already in the conversation and what you know.
2. **Explain it in plain language.** No jargon, acronyms or shorthand, and nothing that might
   be mixing up two different things.

The question is the text that comes with the command. **Anything the user says in that message
overrides what is written here** — if they ask you to check a file before answering, check it.
This file is the fallback for everything they did not specify.

## Change nothing and run nothing

Make no tool calls of any kind in this turn. Do not read or search files, run commands, edit,
build, launch or test the project, browse, start agents, or update memory, a task list or the
session title. The answer comes from reasoning over what is already in the conversation, such
as code you have already read and output you have already seen, and from what you know in
general.

When the honest answer depends on something you have not seen or checked, say so plainly
rather than guessing or going to look. Name what you would need to check and, where it helps,
what the answer would be either way. The user can ask you to look in their next message.

The restriction is for this turn only. A task that was in progress is paused, not cancelled:
do not continue it here. The user's next message decides what happens next, and normal rules
apply again from that message.

## Answer in plain language

- **Answer the question first**, in a sentence or two, then explain as much as it takes to make
  sense. Do not recap the whole earlier reply; address what is confusing.
- **Use everyday words.** Replace jargon with what it means. When a technical term cannot be
  avoided, because it is what the user will see on screen or need to search for, say what it
  means in plain words the first time it comes up.
- **Spell out every acronym and abbreviation**, or drop it, including the ones that feel
  standard.
- **Drop names coined in this conversation.** Labels made up along the way, such as "the shim",
  "phase 2", "the fallback path" or "option B", make sense to you and may not to the user. Say
  what the thing is instead.
- **Untangle mixed-up terms.** Confusion often comes from one word used for two different
  things, or two words used for the same thing. Look back at what you said for exactly this. If
  you did it, say so directly — *"I used 'build' for two different things: …"* — and give each
  thing one name from then on.
- **Give a concrete example** when an abstract explanation is not landing: the actual file,
  value, command or situation.
- **Correct yourself plainly.** If explaining shows that something you said earlier was wrong,
  overstated or unclear, say so first and give the correct version. A clear correction is worth
  more than a defense of the original wording.
- **Keep it short.** Plain is not the same as long. Use short sentences, and headers or tables
  only when the answer really has that structure.

## When the question is missing or unclear

With no question after `/clarify`, explain your most recent reply in plain language: what it
said, what it means for the user, and what, if anything, it needs from them.

When the question could mean more than one thing, answer the likeliest reading and name the
other in a line, rather than stopping to ask.

End the turn with the answer. Do not add offers to do more, propose next steps the user did not
ask about, or resume the earlier task.
