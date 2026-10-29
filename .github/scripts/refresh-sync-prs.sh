#!/usr/bin/env bash
# 指定したブランチ向けに開いている同期PR（sync/）のうち、同期先の更新でコンフリクトしたものを直して push する。
# 同期PRを開いたまま同期先で機能リリースや hotfix リリースが入ると、versionFile・CHANGELOG.md がコンフリクトするため。
# それ以外のファイルのコンフリクトは直さず、PR にコメントする。リポジトリのルートで、全ブランチを fetch した状態で呼ぶ。
# 使い方: refresh-sync-prs.sh <同期先のブランチ>（GH_TOKEN・GH_REPO が必要）
set -euo pipefail
base=$1
script_dir=$(cd "$(dirname "$0")" && pwd)
readonly WAIT_ATTEMPTS=10
readonly WAIT_SECONDS=3

git fetch -q origin
prs=$(gh pr list --state open --base "$base" --json number,headRefName \
  --jq '.[] | select(.headRefName | startswith("sync/")) | "\(.number) \(.headRefName)"')
while read -r number head; do
  if [ -z "$number" ]; then
    continue
  fi
  # 同期先が更新された直後は、mergeable の計算が終わっていないため、結果が出るまで待つ
  state=UNKNOWN
  for _ in $(seq 1 "$WAIT_ATTEMPTS"); do
    state=$(gh pr view "$number" --json mergeable --jq .mergeable)
    if [ "$state" != UNKNOWN ]; then
      break
    fi
    sleep "$WAIT_SECONDS"
  done
  if [ "$state" != CONFLICTING ]; then
    continue
  fi
  # 同期ブランチの名前（sync/<タグ>-to-<同期先>）から、今回のリリースのタグを取り出す
  next=${head#sync/}
  next=${next%%-to-*}
  git switch -q --detach "origin/${head}"
  if git merge -q --no-edit "origin/${base}"; then
    :
  elif result=$("${script_dir}/resolve-sync-conflicts.sh" "origin/${base}" "$next"); then
    git commit -q --no-edit
  else
    git merge --abort
    gh pr comment "$number" --body "${base} の変更とコンフリクトしています。手で解消してください: $(tr '\n' ' ' <<< "$result")"
    continue
  fi
  git push origin "HEAD:refs/heads/${head}"
  gh pr comment "$number" --body "${base} の更新で生じた versionFile・CHANGELOG.md のコンフリクトを、自動で解消しました。"
done <<< "$prs"
