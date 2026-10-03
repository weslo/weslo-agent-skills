#!/usr/bin/env bash
# Lists a pull request's review threads in the current repository, one JSON object per line.
# `ours` marks threads opened by /review-github-pr, identified by the marker its comments carry.
#
# Usage: review-threads.sh <pr-number>
set -euo pipefail

pr="${1:?usage: review-threads.sh <pr-number>}"

gh api graphql -F owner='{owner}' -F repo='{repo}' -F number="$pr" -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line originalLine
          comments(first: 100) {
            nodes { databaseId author { login } originalCommit { oid } body }
          }
        }
      }
    }
  }
}' --jq '
  .data.repository.pullRequest.reviewThreads.nodes[] | {
    thread: .id,
    resolved: .isResolved,
    outdated: .isOutdated,
    path,
    line: (.line // .originalLine),
    comment: .comments.nodes[0].databaseId,
    author: .comments.nodes[0].author.login,
    reviewedCommit: .comments.nodes[0].originalCommit.oid,
    ours: (.comments.nodes[0].body | contains("<!-- review-github-pr -->")),
    body: .comments.nodes[0].body,
    replies: [.comments.nodes[1:][] | {author: .author.login, body}]
  }'
