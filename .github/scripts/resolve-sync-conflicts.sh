#!/usr/bin/env bash
# 同期（保守ブランチのリリースを、新しい保守ブランチ・main に取り込む）で起きたコンフリクトのうち、
# versionFile と CHANGELOG.md だけのものを解消して git add する。マージ中の状態で、リポジトリのルートで呼ぶ。
# - versionFile: 同期先と今回のリリースのうち、新しいバージョンの内容にする
#   （tagpr は versionFile を現在のバージョンとみなすため、古いほうに戻すと番号がずれる）
# - CHANGELOG.md: 同期先の内容に、同期先に無い節をすべて、バージョン順の位置に差し込む
#   （古い同期PRを置き換えた場合、前のバージョンの節も同期先に無い。先頭に差し込むと、別系統の同期PRと
#   同じ位置を書き換えて、後からマージする側がコンフリクトする）
# ほかのファイルがコンフリクトしていたら、そのファイル名を出力して 1 を返す。成功したら、残したバージョンを出力する。
# 使い方: resolve-sync-conflicts.sh <同期先の ref> <今回のリリースのタグ>
set -euo pipefail
base_ref=$1
next_tag=$2
IFS=',' read -ra version_files <<< "$(git config -f .tagpr tagpr.versionFile)"

conflicted=$(git diff --name-only --diff-filter=U)
others=$(grep -vxF -e CHANGELOG.md "${version_files[@]/#/-e}" <<< "$conflicted" || true)
if [ -n "$others" ]; then
  echo "$others"
  exit 1
fi

base_version=$(git show "${base_ref}:${version_files[0]}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
kept=$(printf '%s\n%s\n' "$base_version" "$next_tag" | sort -V | tail -n 1)
if [ "$kept" = "$next_tag" ]; then
  source_ref=$next_tag
else
  source_ref=$base_ref
fi
for f in "${version_files[@]}"; do
  git show "${source_ref}:${f}" > "$f"
done

git show "${next_tag}:CHANGELOG.md" > CHANGELOG.next
git show "${base_ref}:CHANGELOG.md" > CHANGELOG.md
grep '^## \[' CHANGELOG.next | while read -r header; do
  v=${header#'## ['}
  v=${v%%]*}
  if grep -qF "## [${v}]" CHANGELOG.md; then
    continue
  fi
  # その節（次の「## 」の手前まで）を取り出す
  section=$(awk -v head="## [${v}]" '/^## / { if (p) exit; if (index($0, head) == 1) p = 1 } p { print }' CHANGELOG.next)
  # その節より古いバージョンの最初の節の手前に差し込む（無ければ末尾）
  at=$(grep -n '^## \[' CHANGELOG.md | while IFS=: read -r n line; do
    w=${line#'## ['}
    w=${w%%]*}
    if [ "$(printf '%s\n%s\n' "$w" "$v" | sort -V | head -n 1)" = "$w" ]; then
      echo "$n"
      break
    fi
  done)
  if [ -n "$at" ]; then
    { head -n $((at - 1)) CHANGELOG.md; printf '%s\n\n' "$section"; tail -n +"$at" CHANGELOG.md; } > CHANGELOG.tmp
  else
    { cat CHANGELOG.md; printf '\n%s\n' "$section"; } > CHANGELOG.tmp
  fi
  mv CHANGELOG.tmp CHANGELOG.md
done
rm CHANGELOG.next

git add CHANGELOG.md "${version_files[@]}"
echo "$kept"
