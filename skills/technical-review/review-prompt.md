{{brief}} As it develops, we want to periodically review its code and architecture for quality, consistency, organization, and security. Ingest the entire project, including the source code, assets, and Git and GitHub history, read the history of agent conversations that have contributed to it over the last few months, and comprehensively review it all through the following lenses:

# Quality

- Is the project broadly efficient for its purpose?
- Are there repeating patterns in the code that are causing problems, or will cause problems down the line?
- Is the line between code-authored and data-driven behavior effective?
- Is the agentic work on the project efficient?
  - Are agents frequently repeating tasks, or having to re-learn things that other agents already learned?
  - Are agents able to effectively test and validate their work?
  - Are agents communicating effectively, both with the humans on the project and with each other?
- Is the product largely debuggable, both in development and from a live or release build?

# Consistency

- Are the contributing rules clear for humans and agents?
- Is the code quality and style consistent throughout the project?
- Is the comment quality, style, and language consistent throughout the project?
- Are any responsibilities or concepts duplicated, reimplemented where they could be abstracted and reused?

# Organization

- Is the project well organized, for both code and assets?
- Are the lines of responsibility clear across folders, namespaces, and modules (packages, assemblies, crates), or are there concepts in the wrong places?

# Security

- Are there any glaring security anti-patterns or vulnerabilities?
- Are there secrets, tokens, or other strings checked into the project that shouldn't be, now or anywhere in its history?
- Are there local paths or other local machine data checked into the project that shouldn't be?

# Improvements

- For all of the above topics, what are the opportunities for low-hanging-fruit improvements?
- Are there any major red flags that might require a direction shift or pivot?
- What projects would you recommend investing in to improve the project over the next few months?

# Not Interested In

- Design feedback on the product or its features.
- Aesthetic feedback on the art, audio, visual design, or other assets.
- Thoughts on the production framework and planning.

You are not authorized to change anything in this pass.
