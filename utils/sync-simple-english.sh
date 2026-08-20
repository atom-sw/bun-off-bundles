#!/usr/bin/env bash
# Refresh the vendored SimpleEnglish skill in writing/skills/simple-english/.
#
# The skill is a verbatim copy of an upstream subtree, pinned to a commit. Nothing resolves it
# at deploy time: `boff` ships whatever bytes are committed here, so the pin in UPSTREAM.md is
# provenance, not enforcement. This script is the only thing that moves it.
#
# Pin a commit, never a tag: upstream tags its releases sporadically and its latest tag has
# lagged the shipped content by a whole minor version.
#
#   ./utils/sync-simple-english.sh --check      report whether upstream moved; change nothing
#   ./utils/sync-simple-english.sh              copy from upstream HEAD
#   ./utils/sync-simple-english.sh <ref>        copy from a named tag, branch, or commit
#
# Review the result with `git diff` before committing it: this text lands in the context of
# every project the bundle is deployed to.

set -euo pipefail

UPSTREAM_URL="https://github.com/AminBlg/SimpleEnglish.git"
UPSTREAM_SUBDIR="skills/simple-english"
# Copied verbatim, relative to UPSTREAM_SUBDIR. UPSTREAM.md is ours and is never overwritten
# wholesale: only its pin is rewritten, so the licence notice below it survives.
FILES=(SKILL.md references/checklist.md references/use-cases.md)

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dest="$repo_root/writing/skills/$( basename "$UPSTREAM_SUBDIR" )"
pin_file="$dest/UPSTREAM.md"

die() { printf 'sync-simple-english: %s\n' "$*" >&2; exit 1; }

[[ -f $pin_file ]] || die "no pin file at $pin_file"

pinned_sha=$(sed -n 's/^| Pinned commit | `\([0-9a-f]\{40\}\)` |$/\1/p' "$pin_file")
pinned_version=$(sed -n 's/^| Upstream version | \(.*\) |$/\1/p' "$pin_file")
[[ -n $pinned_sha ]] || die "cannot read the pinned commit from $pin_file"

mode=copy
ref=HEAD
case ${1-} in
    --check) mode=check ;;
    -h | --help) sed -n '2,18p' "${BASH_SOURCE[0]}"; exit 0 ;;
    '') ;;
    -*) die "unknown option: $1" ;;
    *) ref=$1 ;;
esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# A blobless clone keeps this quick: the eval directory upstream is far larger than the skill.
git clone -q --filter=blob:none "$UPSTREAM_URL" "$work/src"
git -C "$work/src" checkout -q "$ref"

new_sha=$(git -C "$work/src" rev-parse HEAD)
new_date=$(git -C "$work/src" log -1 --format=%cs)
new_version=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$work/src/.claude-plugin/plugin.json" | head -1)

if [[ $mode == check ]]; then
    printf 'pinned  : %s (%s, version %s)\n' "${pinned_sha:0:12}" "$(git -C "$work/src" log -1 --format=%cs "$pinned_sha" 2>/dev/null || echo 'unknown date')" "$pinned_version"
    printf 'upstream: %s (%s, version %s)\n' "${new_sha:0:12}" "$new_date" "$new_version"
    if [[ $pinned_sha == "$new_sha" ]]; then
        echo '=> up to date'
        exit 0
    fi
    behind=$(git -C "$work/src" rev-list --count "$pinned_sha..$new_sha" 2>/dev/null || echo '?')
    printf '=> %s commit(s) behind; re-run without --check, then review with git diff\n' "$behind"
    # Show whether the change touches the files we actually vendor.
    if git -C "$work/src" diff --quiet "$pinned_sha" "$new_sha" -- "$UPSTREAM_SUBDIR" 2>/dev/null; then
        echo '   (no change under '"$UPSTREAM_SUBDIR"' — the vendored copy is still current)'
    else
        git -C "$work/src" diff --stat "$pinned_sha" "$new_sha" -- "$UPSTREAM_SUBDIR" 2>/dev/null | sed 's/^/   /'
    fi
    exit 0
fi

for rel in "${FILES[@]}"; do
    src="$work/src/$UPSTREAM_SUBDIR/$rel"
    [[ -f $src ]] || die "upstream is missing $UPSTREAM_SUBDIR/$rel at $ref; its layout changed"
    mkdir -p "$(dirname "$dest/$rel")"
    cp "$src" "$dest/$rel"
done

# Rewrite only the pin rows, so the licence notice and the prose around them stay put.
# `#` as the delimiter: the rows themselves are full of pipes.
tmp=$(mktemp)
sed -e "s#^| Pinned commit | \`.*\` |\$#| Pinned commit | \`$new_sha\` |#" \
    -e "s#^| Commit date | .* |\$#| Commit date | $new_date |#" \
    -e "s#^| Upstream version | .* |\$#| Upstream version | $new_version |#" \
    -e "s#^| Vendored on | .* |\$#| Vendored on | $(date +%F) |#" \
    "$pin_file" > "$tmp"
mv "$tmp" "$pin_file"

printf 'updated %d file(s) from %s (%s, version %s)\n' "${#FILES[@]}" "${new_sha:0:12}" "$new_date" "$new_version"
echo 'review with: git diff'
