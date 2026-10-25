#!/usr/bin/env bash
# Links each skill in this repo into ~/.claude/skills, where Claude Code loads it in every project.
# Safe to re-run: existing links are replaced, and an entry that is not a link is left alone.
# On Windows each link is a real symlink when Windows allows one, and a directory junction otherwise.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.claude/skills"
mkdir -p "$target"

case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) windows=true ;;
    *) windows=false ;;
esac

# Runs a cmd.exe command with its arguments untouched; Git Bash and MSYS2 would turn a switch like /J into a path.
win_cmd() {
    MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' cmd /c "$@"
}

# On Windows, ln -s copies the directory unless told to make a native symlink, and a native symlink
# needs Developer Mode or an elevated shell. nativestrict makes ln fail instead of copying, and a
# junction, which needs neither, is made in its place. ln can't replace a junction, so an existing
# link is removed first with rmdir, which removes only the link and never its target.
link_windows() {
    local skill="$1" link="$2"
    if [[ -L "$link" ]]; then
        win_cmd rmdir "$(cygpath -w "$link")"
    fi
    if MSYS=winsymlinks:nativestrict CYGWIN=winsymlinks:nativestrict ln -sn "$skill" "$link" 2>/dev/null; then
        echo "linked $link -> $skill"
    else
        win_cmd mklink /J "$(cygpath -w "$link")" "$(cygpath -w "$skill")" >/dev/null
        echo "linked $link -> $skill (junction)"
    fi
}

for skill in "$repo"/skills/*/; do
    skill="${skill%/}"
    link="$target/$(basename "$skill")"
    if [[ -e "$link" && ! -L "$link" ]]; then
        echo "skipped $link: it exists and is not a link" >&2
        continue
    fi
    if $windows; then
        link_windows "$skill" "$link"
    else
        ln -sfn "$skill" "$link"
        echo "linked $link -> $skill"
    fi
done
