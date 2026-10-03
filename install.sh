#!/usr/bin/env bash
# Links each skill in this repo into ~/.claude/skills, where Claude Code loads it in every project.
# Safe to re-run: existing links are replaced, and an entry that is not a link is left alone.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.claude/skills"
mkdir -p "$target"

for skill in "$repo"/skills/*/; do
    skill="${skill%/}"
    link="$target/$(basename "$skill")"
    if [[ -e "$link" && ! -L "$link" ]]; then
        echo "skipped $link: it exists and is not a link" >&2
        continue
    fi
    ln -sfn "$skill" "$link"
    echo "linked $link -> $skill"
done
