# tagpr で詰まった点

保守ブランチからもリリースしようとして詰まった点と、その対処です。最初は「保守ブランチでも tagpr を動かせばいいのでは」と考えていましたが、最終的に tagpr は main 専用にしました。

## 前提: tagpr の動き

詰まった点に関係するところだけ押さえておきます。

- main が更新されるたびに、リリース PR（`Release for vX.Y.Z`）を作る・更新する
- リリース PR をマージすると、タグと GitHub Release を作る
- `versionFile` を指定すると、現在のバージョンは versionFile の値で決まる（タグより優先される）
- `releaseBranch`（環境変数なら `TAGPR_RELEASE_BRANCH`）で、リリース対象のブランチを変えられる

## 1. 2本のブランチで動かすと、リリース PR のブランチ名がぶつかる {#branch-name}

main と `release/v1.0` の両方で tagpr を動かしたところ、片方が `422 Reference already exists` で失敗しました。

tagpr のリリース PR は、`tagpr-from-<最新タグ>` という名前のブランチから作られます。接頭辞は定数で、設定では変えられません。

```go
// tagpr.go（v1.21.4）
branchPrefix = "tagpr-from-"
// ...
rcBranch := fmt.Sprintf("%s%s%s", branchPrefix, branchSafePrefix(tp.normalizedTagPrefix), currVer.Tag())
```

main も保守ブランチも、最新タグが同じ（たとえば v1.0.0）なら、どちらも `tagpr-from-v1.0.0` を作ろうとします。先に作った側が勝ち、もう片方は失敗します。

対処: 保守ブランチでは tagpr を動かさず、hotfix のリリースは HOTFIX_RELEASE で行う。

## 2. 最新タグは全ブランチで共通で、versionFile が優先される {#latest-tag}

保守ブランチで hotfix のタグ（v1.0.1）を付けると、main の tagpr もそれを最新タグとして扱います。tagpr の現在のバージョンは、全ブランチの semver タグのうち最新のものだからです。

さらに、`versionFile` を指定しているとその値が優先されます。hotfix を main に取り込み忘れて main の versionFile が古いまま残ると、tagpr は誤ったバージョンでリリース PR を作り続けます。

対処: tagpr を動かす前にガードを入れる。

- 最新タグが main に取り込まれていない（同期 PR のマージ待ち）ときは、リリース PR を更新しない（警告）
- main の versionFile が最新タグより古いときは、リリース PR を更新しない（エラー）

リリース PR をマージした直後は、versionFile のほうがタグより新しいのが正常です。そのため、「違うとき」ではなく「古いとき」だけ止めます。

```bash
# tagpr.yaml の Guard から抜粋
latest=$(git tag --list 'v*' --sort=-v:refname | head -n 1)
IFS=',' read -ra version_files <<< "$(git config -f .tagpr tagpr.versionFile)"
current=$(grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "${version_files[0]}" | head -n 1)
if ! git merge-base --is-ancestor "$latest" HEAD; then
  echo "::warning::最新タグ ${latest} が main に未反映（同期PR待ち）のためスキップ"
  echo "run=false" >> "$GITHUB_OUTPUT"
elif [ "$current" != "$latest" ] && [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n 1)" = "$latest" ]; then
  echo "::error::versionFile（${current}）が最新タグ ${latest} より古いためスキップ"
  echo "run=false" >> "$GITHUB_OUTPUT"
else
  echo "run=true" >> "$GITHUB_OUTPUT"
fi
```

## 3. 古いリリース PR が残る {#stale-release-pr}

hotfix のタグを付けるたびに、main のリリース PR が新しく作られ、古いものが開いたまま残りました。

原因は 1 と同じブランチ名です。最新タグが v1.0.0 から v1.0.1 に変わると、リリース PR のブランチ名も `tagpr-from-v1.0.0` から `tagpr-from-v1.0.1` に変わります。tagpr から見ると別の PR なので、新しく作られます。

対処: 2か所で Close する。

- TAGPR: tagpr の出力（`pull_request`）と番号が違う、`tagpr` ラベル付きの PR を Close する
- HOTFIX_RELEASE: リリースした時点で、main のリリース PR を Close する。同期 PR のマージ待ちの間は TAGPR がガードで止まるので、TAGPR 側では Close できないため

## 4. 機能リリースで minor を上げたいが、ラベルは次の実行から読まれる {#minor-label}

tagpr は、リリース PR に `tagpr:minor` ラベルが付いていれば minor を上げます。ところが、ラベルを付けたその実行では patch のままでした。ラベルは、次に tagpr が動いたときに読まれるからです。

対処: ラベルが無ければ付けて、同じジョブの中で tagpr をもう一度動かす。1回目の tagpr がリリース PR のブランチに切り替えたままなので、間に `git checkout -f main` を挟む。

```yaml
- name: Mark release PR as minor
  id: minor
  if: steps.tagpr.outputs.pull_request != ''
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    PR_JSON: ${{ steps.tagpr.outputs.pull_request }}
  run: |
    if jq -e '.labels[]? | select(.name == "tagpr:minor")' <<< "$PR_JSON" > /dev/null; then
      echo "relabeled=false" >> "$GITHUB_OUTPUT"
      exit 0
    fi
    gh label create 'tagpr:minor' --color '0e8a16' --force
    gh pr edit "$(jq -r '.number' <<< "$PR_JSON")" --add-label 'tagpr:minor'
    echo "relabeled=true" >> "$GITHUB_OUTPUT"

- name: Restore release branch
  if: steps.minor.outputs.relabeled == 'true'
  run: git checkout -f main

- uses: Songmu/tagpr@242e22916eb775d6e359959fe3ba5c497de4a01a # v1.20.2
  if: steps.minor.outputs.relabeled == 'true'
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 5. `fixedMajorVersion` では足りなかった {#fixed-major-version}

tagpr には `fixedMajorVersion` という設定があります。指定したメジャーバージョンのタグだけを見るようにする機能で、「v1 ブランチで v1.x.x を、main で v2.x.x をリリースする」使い方が想定されています。

```ini
[tagpr]
    releaseBranch = v1
    fixedMajorVersion = 1
```

これは、旧メジャー（v1）を別ブランチで保守しつつ、最新の修正は main から出す前提です。v1 ブランチと main（v2）は基準にするタグが違うので、ブランチ名もぶつかりません。

やりたかったのは、本番で動いている系統（v1.1.x）へのパッチです。この系統は main の最新タグと同じ系統なので、仮に minor 単位で絞り込めたとしても、`tagpr-from-v1.1.1` で main とぶつかります。機能リリースのたびに major を上げても、同じ理由でぶつかります。

`fixedMajorVersion` を追加した PR（[Songmu/tagpr#296](https://github.com/Songmu/tagpr/pull/296)）では、minor 単位への拡張が今後の論点として挙がっていました。

## 6. 同期のときの CHANGELOG.md {#changelog}

tagpr そのものではなく、自前で同期 PR を作るときの話です。hotfix のタグを main に取り込むと、CHANGELOG.md がよくコンフリクトします。自動で解消するようにしたところ、2つ詰まりました。

1つ目は、今回の節を CHANGELOG.md の先頭に差し込んでいたこと。別の系統の同期 PR が main に同時に開いていると、どちらも先頭を書き換えるので、後からマージする側がコンフリクトします。

対処: バージョン順の位置（今回より古いバージョンの最初の節の手前）に差し込む。

2つ目は、節が抜けたこと。同じ保守ブランチの古い同期 PR（v1.0.4）を新しいもの（v1.0.5）に置き換えたとき、今回の節（v1.0.5）だけを差し込んでいたので、v1.0.4 の節が main に入りませんでした。検証リポジトリの main の CHANGELOG.md に v1.0.4 の節が無いのは、このときのなごりです。

対処: 同期先に無い節をすべて、バージョン順に差し込む。v1.2.4 を v1.2.5 に置き換えた同期 PR（[#48](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/48)）には、両方の節が入っています。
