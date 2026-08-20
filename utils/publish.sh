#!/usr/bin/env bash
#
# publish.sh — copy a snapshot of `dev` onto `main`, one commit per publication.
#
# `dev` is where the work happens. `main` is what people deploy from, and it carries one
# commit per publication whose tree is `dev`'s tree minus everything `.mergeignore` names.
#
# A snapshot, not a merge. `git merge dev` would make every development commit reachable from
# `main`, publishing the whole history and every historical blob of the excluded files —
# excluding a path from the merged *tree* does nothing about *history*. It would also raise a
# modify/delete conflict on each excluded file that `dev` later edits. The snapshot makes both
# impossible, and `git log --oneline main` reads as a list of publications.
#
# The snapshot is assembled in a temporary index, so no branch is ever checked out and the
# working tree never moves. `update-ref` is given the expected old value, making it a
# compare-and-swap: a concurrent update aborts the publication rather than losing it.
#
# Each bundle is tagged `<bundle>/<version>` from its own `meta.version`, so a user can pin one:
#
#     extends: https://github.com/atom-sw/bun-off-bundles.git/writing@writing/0.1.0
#
# A bundle whose files changed must have its version bumped, or publishing refuses. That is the
# only thing keeping the tags honest, since this repository has no changelog.
#
# Usage:
#     ./utils/publish.sh                 publish dev onto main
#     ./utils/publish.sh -n              show what would happen, write nothing
#     ./utils/publish.sh --edit          edit the generated message first
#     ./utils/publish.sh --bootstrap     create main as a root commit (first run only)
#     ./utils/publish.sh --amend         replace the publication at the tip of main

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────────────────
SRC_BRANCH="dev"
REL_BRANCH="main"
IGNORE_FILE=".mergeignore"
# Paths a publication cannot omit. Every bundle directory is added to this at run time.
REQUIRED_PATHS=("README.md" "LICENSE")

# ── Globals ───────────────────────────────────────────────────────────────────────────────
SCRIPT_NAME="$(basename "$0")"
SOURCE_REF="$SRC_BRANCH"
MESSAGE=""          # -m: replaces the generated subject
MESSAGE_FILE=""     # -F: replaces the whole generated message
EDIT=0
AMEND=0
BOOTSTRAP=0
DRY_RUN=0
FORCE=0
SKIP_CHECKS=0
YES=0
TMP_DIR=""

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
info() { printf '%s: %s\n' "$SCRIPT_NAME" "$*"; }

cleanup() { if [[ -n "$TMP_DIR" ]]; then rm -rf -- "$TMP_DIR"; fi; }
trap cleanup EXIT

usage() {
    sed -n '3,30p' "$0" | sed -e 's/^# \{0,1\}//'
    exit 0
}

# A `.mergeignore` line becomes a git pathspec. `:(glob)` gives .gitignore-like intuition:
# `*` stops at a `/`, so a top-level `*.md` cannot reach into a bundle's own files. A line
# that already carries pathspec magic passes through untouched.
to_pathspec() {
    local line="${1%/}"
    case "$line" in
        :*) printf '%s' "$line" ;;
        *) printf ':(glob)%s' "$line" ;;
    esac
}

confirm() {
    local answer
    read -rp "$1 [y/N] " answer
    case "$answer" in
        [yY] | [yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Directories holding a `boff.yaml` at a ref. Filtering on the manifest rather than on "any
# directory" is what keeps `utils/` out of the bundle list.
bundle_dirs() {
    git ls-tree -r --name-only "$1" \
        | sed -n 's|^\([^/]*\)/boff\.yaml$|\1|p' \
        | sort
}

# `meta.version` of one bundle at a ref, read without a YAML parser so the script needs no
# Python. The address range stops at the next top-level key, so only `meta:`'s own version
# can match.
bundle_version() {
    local ref="$1" bundle="$2" version
    version="$(git show "${ref}:${bundle}/boff.yaml" 2> /dev/null \
        | sed -n '/^meta:/,/^[a-z_]*:/ s/^  version: *"\{0,1\}\([0-9][0-9.]*\)"\{0,1\}[[:space:]]*$/\1/p' \
        | head -1)"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
        || die "cannot read meta.version of '$bundle' at $ref (got '${version}'); it must be a quoted X.Y.Z"
    printf '%s' "$version"
}

# The dev commit the previous publication was built from, recorded as a trailer so the next
# run can tell what changed. Empty when there is no previous publication.
previous_source() {
    git log -1 --format=%B "$1" 2> /dev/null | sed -n 's/^Source-Commit: *\([0-9a-f]\{7,40\}\) *$/\1/p' | head -1
}

# Remotes whose copy of the published branch holds commits the local one does not.
release_branch_lag() {
    local commit="$1" remote rref
    for remote in $(git remote); do
        rref="refs/remotes/${remote}/${REL_BRANCH}"
        git rev-parse --verify --quiet "$rref" > /dev/null || continue
        if git merge-base --is-ancestor "$rref" "$commit"; then continue; fi
        if git merge-base --is-ancestor "$commit" "$rref"; then
            printf '%s behind\n' "$remote"
        else
            printf '%s diverged\n' "$remote"
        fi
    done
}

# First remote whose published branch already contains a commit, or nothing.
published_on() {
    local commit="$1" remote rref
    for remote in $(git remote); do
        rref="refs/remotes/${remote}/${REL_BRANCH}"
        git rev-parse --verify --quiet "$rref" > /dev/null || continue
        if git merge-base --is-ancestor "$commit" "$rref"; then
            printf '%s' "$remote"
            return 0
        fi
    done
}

is_publish_commit() {
    [[ "$(git log -1 --format=%s "$1")" == "Publish "*"." ]]
}

# ── Arguments ─────────────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s | --source) SOURCE_REF="${2:?missing value for $1}"; shift 2 ;;
        -r | --release) REL_BRANCH="${2:?missing value for $1}"; shift 2 ;;
        -m | --message) MESSAGE="${2:?missing value for $1}"; shift 2 ;;
        -F | --message-file) MESSAGE_FILE="${2:?missing value for $1}"; shift 2 ;;
        --edit) EDIT=1; shift ;;
        --amend) AMEND=1; shift ;;
        --bootstrap) BOOTSTRAP=1; shift ;;
        -n | --dry-run) DRY_RUN=1; shift ;;
        -f | --force) FORCE=1; shift ;;
        --skip-checks) SKIP_CHECKS=1; shift ;;
        -y | --yes) YES=1; shift ;;
        -h | --help) usage ;;
        *) die "unknown option: $1 (try -h for help)" ;;
    esac
done

TMP_DIR="$(mktemp -d -t boff-publish.XXXXXX)"
MSG_FILE="$TMP_DIR/message"
TMP_INDEX="$TMP_DIR/index"

# ── Pre-flight ────────────────────────────────────────────────────────────────────────────
git rev-parse --git-dir > /dev/null 2>&1 || die "not inside a git repository"
git diff-index --quiet HEAD -- || die "working tree has uncommitted changes — commit or stash first"
git rev-parse --verify --quiet "$SOURCE_REF" > /dev/null || die "no such ref: $SOURCE_REF"
git cat-file -e "${SOURCE_REF}:${IGNORE_FILE}" 2> /dev/null \
    || die "$SOURCE_REF has no $IGNORE_FILE — a publication would ship everything"

if grep -qx "branch refs/heads/${REL_BRANCH}" <<< "$(git worktree list --porcelain)"; then
    die "'$REL_BRANCH' is checked out — switch to $SRC_BRANCH and re-run"
fi

SOURCE_SHA="$(git rev-parse --verify "$SOURCE_REF")"

TIP=""
PARENT=""
if git rev-parse --verify --quiet "refs/heads/${REL_BRANCH}" > /dev/null; then
    [[ "$BOOTSTRAP" -eq 1 ]] && die "--bootstrap given but '$REL_BRANCH' already exists"
    TIP="$(git rev-parse --verify "refs/heads/${REL_BRANCH}")"
    PARENT="$TIP"

    while read -r LAG_REMOTE LAG_KIND; do
        [[ -z "$LAG_REMOTE" ]] && continue
        LAG_MSG="'$REL_BRANCH' is $LAG_KIND '${LAG_REMOTE}/${REL_BRANCH}': the publication would be built on an outdated history."
        if [[ "$LAG_KIND" == "behind" ]]; then
            LAG_MSG+=" Catch up first: git fetch $LAG_REMOTE && git branch -f $REL_BRANCH ${LAG_REMOTE}/${REL_BRANCH}"
        fi
        if [[ "$FORCE" -eq 1 ]]; then warn "$LAG_MSG"; else die "$LAG_MSG"; fi
    done < <(release_branch_lag "$TIP")

    if [[ "$AMEND" -eq 1 ]]; then
        is_publish_commit "$TIP" || die "the tip of '$REL_BRANCH' is not a publication commit; --amend would discard it"
        [[ "$(git rev-list --parents -n1 "$TIP" | wc -w)" -eq 2 ]] \
            || die "the tip of '$REL_BRANCH' is a root or a merge; --amend expects exactly one parent"
        PUBLISHED_ON="$(published_on "$TIP")"
        if [[ -n "$PUBLISHED_ON" ]]; then
            if [[ "$FORCE" -eq 1 ]]; then
                warn "the tip of '$REL_BRANCH' is already on '$PUBLISHED_ON'; --amend rewrites published history"
            else
                die "the tip of '$REL_BRANCH' is already on '$PUBLISHED_ON' — publish a new snapshot instead of amending"
            fi
        fi
        PARENT="$(git rev-parse --verify "${TIP}^")"
    fi
elif [[ "$BOOTSTRAP" -ne 1 ]]; then
    die "'$REL_BRANCH' does not exist — pass --bootstrap to create it as a root commit"
fi

# ── Which bundles changed, and at what version ────────────────────────────────────────────
mapfile -t BUNDLES < <(bundle_dirs "$SOURCE_REF")
(( ${#BUNDLES[@]} )) || die "$SOURCE_REF holds no bundle (no */boff.yaml)"
for bundle in "${BUNDLES[@]}"; do
    REQUIRED_PATHS+=("${bundle}/boff.yaml")
done

PREV_SOURCE=""
if [[ -n "$PARENT" ]]; then
    PREV_SOURCE="$(previous_source "$PARENT")"
    if [[ -n "$PREV_SOURCE" ]] && ! git rev-parse --verify --quiet "${PREV_SOURCE}^{commit}" > /dev/null; then
        warn "the previous publication names source commit $PREV_SOURCE, which is not in this repository; treating this as a first publication"
        PREV_SOURCE=""
    fi
fi

CHANGED=()
for bundle in "${BUNDLES[@]}"; do
    if [[ -z "$PREV_SOURCE" ]]; then
        CHANGED+=("$bundle")
    elif ! git diff --quiet "$PREV_SOURCE" "$SOURCE_SHA" -- "$bundle"; then
        CHANGED+=("$bundle")
    fi
done

# A changed bundle whose tag already exists was edited without bumping its version.
NEW_TAGS=()
SUMMARY=()
for bundle in "${CHANGED[@]}"; do
    version="$(bundle_version "$SOURCE_REF" "$bundle")"
    tag="${bundle}/${version}"
    if git rev-parse --verify --quiet "refs/tags/${tag}" > /dev/null; then
        MSG="bundle '$bundle' changed since the last publication but is still at version $version — bump meta.version in ${bundle}/boff.yaml"
        if [[ "$FORCE" -eq 1 ]]; then warn "$MSG (no tag will be created)"; else die "$MSG"; fi
    else
        NEW_TAGS+=("$tag")
    fi
    SUMMARY+=("${bundle} ${version}")
done

# ── The message ───────────────────────────────────────────────────────────────────────────
if [[ -n "$MESSAGE_FILE" ]]; then
    [[ -f "$MESSAGE_FILE" ]] || die "no such file: $MESSAGE_FILE"
    cat "$MESSAGE_FILE" > "$MSG_FILE"
else
    if [[ -n "$MESSAGE" ]]; then
        SUBJECT="$MESSAGE"
    elif (( ${#SUMMARY[@]} )); then
        SUBJECT="Publish $(printf '%s, ' "${SUMMARY[@]}" | sed 's/, $//')."
    else
        SUBJECT="Publish (no bundle changed)."
    fi
    { printf '%s\n\n' "$SUBJECT"
      if [[ -n "$PREV_SOURCE" ]]; then
          git log --format='  %h %s' "${PREV_SOURCE}..${SOURCE_SHA}"
      else
          git log --format='  %h %s' -n 20 "$SOURCE_SHA"
      fi
      printf '\nSource-Commit: %s\n' "$SOURCE_SHA"
    } > "$MSG_FILE"
fi

if [[ "$EDIT" -eq 1 ]]; then
    "${EDITOR:-vi}" "$MSG_FILE"
    [[ -s "$MSG_FILE" ]] || die "empty message — aborting"
    grep -q '^Source-Commit: ' "$MSG_FILE" \
        || warn "the message no longer carries a Source-Commit trailer; the next publication will not know what changed"
fi

# ── Build the snapshot in a temporary index ───────────────────────────────────────────────
export GIT_INDEX_FILE="$TMP_INDEX"
git read-tree "$SOURCE_REF"

# The ignore file describes the published branch, so it never belongs on it.
PATHSPECS=("$(to_pathspec "$IGNORE_FILE")")
info "=== $IGNORE_FILE (at $SOURCE_REF) ==="
while IFS= read -r line; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "$line" || "$line" == \#* ]]; then continue; fi
    spec="$(to_pathspec "$line")"
    PATHSPECS+=("$spec")
    printf '  %-24s %s file(s)\n' "$line" "$(git ls-files -- "$spec" | wc -l)"
done < <(git show "${SOURCE_REF}:${IGNORE_FILE}")

mapfile -d '' -t DROP < <(git ls-files -z -- "${PATHSPECS[@]}")
if (( ${#DROP[@]} )); then
    git update-index --force-remove -- "${DROP[@]}"
fi

for path in "${REQUIRED_PATHS[@]}"; do
    git ls-files --error-unmatch -- "$path" > /dev/null 2>&1 \
        || die "$IGNORE_FILE excludes '$path', which a publication cannot omit"
done

TREE="$(git write-tree)"
unset GIT_INDEX_FILE

# ── Validate the filtered tree ────────────────────────────────────────────────────────────
# The gate runs on the snapshot rather than the working tree, because the failure this guards
# against is a `.mergeignore` pathspec that quietly guts a bundle. Only the filtered tree can
# show that. Relative `extends:` resolves because every bundle is present.
if [[ "$SKIP_CHECKS" -eq 1 ]]; then
    warn "skipping bundle validation (--skip-checks)"
elif ! command -v boff > /dev/null 2>&1; then
    warn "boff is not on PATH — skipping bundle validation"
else
    info "=== validating $(( ${#BUNDLES[@]} )) bundle(s) in the snapshot ==="
    mkdir -p "$TMP_DIR/snapshot" "$TMP_DIR/scratch"
    git archive "$TREE" | tar -x -C "$TMP_DIR/snapshot"
    for bundle in "${BUNDLES[@]}"; do
        [[ -f "$TMP_DIR/snapshot/$bundle/boff.yaml" ]] \
            || die "'$bundle' lost its manifest in the snapshot — check $IGNORE_FILE"
        if ! (cd "$TMP_DIR/scratch" && boff deploy "$TMP_DIR/snapshot/$bundle" \
                --platform claude --dry-run > "$TMP_DIR/validate.log" 2>&1); then
            sed -e 's/^/    /' "$TMP_DIR/validate.log" >&2
            die "bundle '$bundle' does not load from the snapshot"
        fi
        printf '  %-24s ok\n' "$bundle"
    done
fi

# ── Review ────────────────────────────────────────────────────────────────────────────────
info "=== dropped from the snapshot (${#DROP[@]}) ==="
if (( ${#DROP[@]} )); then printf '  %s\n' "${DROP[@]}"; fi

info "=== tags to create (${#NEW_TAGS[@]}) ==="
if (( ${#NEW_TAGS[@]} )); then printf '  %s\n' "${NEW_TAGS[@]}"; fi

if [[ -n "$PARENT" ]]; then
    info "=== $REL_BRANCH ($(git rev-parse --short "$PARENT")) to the snapshot ==="
    git --no-pager diff --stat "$PARENT" "$TREE"
else
    info "=== the snapshot (a root commit) ==="
    git --no-pager ls-tree --name-only "$TREE" | sed -e 's/^/  /'
fi

info "=== commit message ==="
sed -e 's/^/  /' "$MSG_FILE"

if [[ "$DRY_RUN" -eq 1 ]]; then
    info "dry run — no commit, no tag"
    exit 0
fi

if [[ "$YES" -ne 1 ]]; then
    confirm "publish this snapshot onto '$REL_BRANCH'?" || { info "aborted — nothing was written"; exit 0; }
fi

# ── Commit and tag ────────────────────────────────────────────────────────────────────────
if [[ -n "$PARENT" ]]; then
    COMMIT="$(git commit-tree "$TREE" -p "$PARENT" -F "$MSG_FILE")"
else
    COMMIT="$(git commit-tree "$TREE" -F "$MSG_FILE")"
fi
# The expected-old-value argument makes this a compare-and-swap: a concurrent update aborts the
# publication rather than losing it. Under --amend the old tip stays reachable from the reflog.
git update-ref "refs/heads/${REL_BRANCH}" "$COMMIT" "$TIP"

for tag in "${NEW_TAGS[@]}"; do
    git tag -f "$tag" "$COMMIT" > /dev/null
done

info "published $(git rev-parse --short "$COMMIT") onto '$REL_BRANCH'"
if (( ${#NEW_TAGS[@]} )); then info "tagged: ${NEW_TAGS[*]}"; fi

# ── Push ──────────────────────────────────────────────────────────────────────────────────
REMOTE="$(git remote | head -1)"
if [[ -n "$REMOTE" ]]; then
    PUSH_FLAG=""
    if [[ "$AMEND" -eq 1 || "$BOOTSTRAP" -eq 1 ]]; then PUSH_FLAG=" --force-with-lease"; fi
    info "push with:"
    printf '  git push%s %s %s\n' "$PUSH_FLAG" "$REMOTE" "$REL_BRANCH"
    if (( ${#NEW_TAGS[@]} )); then
        printf '  git push %s %s\n' "$REMOTE" "${NEW_TAGS[*]}"
    fi
    printf '  git push %s %s\n' "$REMOTE" "$SRC_BRANCH"
fi
