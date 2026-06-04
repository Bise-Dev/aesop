#!/usr/bin/env bash
# aesop: gather all context for a PR (or the current branch's PR).
# Usage: gather-pr.sh [<pr-number|url>]
# Prints delimited sections to stdout. Requires: gh (authenticated), jq.
#
# jq notes (interactive shells): avoid the "not equal" operator (history
# expansion eats it) - use `length > 0`; avoid `\(...)` interpolation - use `+`.
set -euo pipefail

PR="${1:-}"

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Resolve PR: explicit arg, else the current branch's PR.
if [ -z "$PR" ]; then
  PR="$(gh pr view --json number -q .number 2>/dev/null || true)"
  if [ -z "$PR" ]; then
    echo "AESOP_ERROR: no pull request associated with the current branch." >&2
    echo "Pass a PR number or URL, e.g. /aesop 123" >&2
    exit 3
  fi
fi

emit() { printf '\n===%s===\n' "$1"; }

emit METADATA
gh pr view "$PR" --json number,title,body,author,state,baseRefName,headRefName,additions,deletions,changedFiles,url,labels,isDraft,mergeable

emit FILES
gh pr view "$PR" --json files \
  --jq '.files[] | .path + " | +" + (.additions|tostring) + " -" + (.deletions|tostring)'

emit COMMITS
gh pr view "$PR" --json commits \
  --jq '.commits[] | .oid + " " + .messageHeadline'

emit COMMENTS
gh pr view "$PR" --json comments \
  --jq '.comments[] | "**" + .author.login + "**: " + .body' 2>/dev/null || true

emit REVIEWS
gh pr view "$PR" --json reviews \
  --jq '.reviews[] | select(.body | length > 0) | "**" + .author.login + "** (" + .state + "): " + .body' 2>/dev/null || true

emit INLINE_COMMENTS
gh api "repos/$REPO/pulls/$PR/comments" --paginate \
  --jq '.[] | "**" + .user.login + "** on `" + .path + "`:\n" + .body + "\n---"' 2>/dev/null || true

emit DIFF
gh pr diff "$PR"

emit END
