# 導入手順

検証リポジトリの構成を、自分のリポジトリに入れて試す手順です。まずは新しいリポジトリで試し、動きを確かめてから実際のリポジトリに入れるのがおすすめです。

## 1. ファイルを持っていく

| ファイル | 内容 | 書き換えるところ |
| --- | --- | --- |
| [`.tagpr`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.tagpr) | tagpr の設定 | `versionFile` |
| [`.github/workflows/tagpr.yaml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/workflows/tagpr.yaml) | TAGPR | CI の起動（後述） |
| [`.github/workflows/hotfix-release.yaml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/workflows/hotfix-release.yaml) | HOTFIX_RELEASE | CI の起動（後述）、CHANGELOG.md の日付のタイムゾーン（`Asia/Tokyo`） |
| [`.github/scripts/resolve-sync-conflicts.sh`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/scripts/resolve-sync-conflicts.sh) | 同期のコンフリクトの解消 | なし（実行権限を付けたまま置く） |
| [`.github/scripts/refresh-sync-prs.sh`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/scripts/refresh-sync-prs.sh) | 同期 PR の修正 | なし（実行権限を付けたまま置く） |
| [`.github/release.yml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/release.yml) | Release Notes から tagpr のリリース PR を外す | なし |
| [`.github/workflows/ci.yaml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/workflows/ci.yaml) | ダミーの CI | 自分の CI に置き換える（後述） |
| `CHANGELOG.md` | 1行目が見出し（`# Changelog`） | なし |

`.tagpr` は次の内容です。

```ini
[tagpr]
	vPrefix = true
	releaseBranch = main
	versionFile = deploy/dev/image-tag.jsonnet,deploy/pro/image-tag.jsonnet
	release = true
	changelog = true
```

versionFile には、次の前提があります。

- 1つ目のファイルに `vX.Y.Z` の形でバージョンが書いてある（TAGPR のガードは、1つ目のファイルで最初に見つかった `vX.Y.Z` を現在のバージョンとみなす）
- どのファイルも、現在のバージョンの文字列をそのまま含んでいる（HOTFIX_RELEASE は、現在のバージョンの文字列を次のバージョンに置き換える）

## 2. リポジトリの設定

Settings → Actions → General の「Workflow permissions」で、「Allow GitHub Actions to create and approve pull requests」をオンにします。tagpr のリリース PR と、同期 PR を作るために要ります。

ワークフローの権限（`contents: write` など）は、各ワークフローの `permissions` で指定しています。

## 3. 最初のタグと保守ブランチを作る

TAGPR は、タグが1つも無いと何もしません。最初の保守ブランチも、TAGPR がタグを作ったときにしかできません。最初の1回だけ、手で作ります。

```bash
# versionFile と CHANGELOG.md を入れたコミットにタグを付ける（versionFile の値は v1.0.0）
git tag v1.0.0
git push origin v1.0.0

# そのタグから保守ブランチを作る
git branch release/v1.0 v1.0.0
git push origin release/v1.0
```

## 4. 動かしてみる

1. `release/v1.0` に向けて修正 PR を作り、マージする

2. Actions のページから HOTFIX_RELEASE を実行する（「Use workflow from」は main、`branch` は `release/v1.0`）

3. v1.0.1 のタグと GitHub Release、main への同期 PR ができていることを確かめる

4. main に機能の PR をマージする。TAGPR は「最新タグ v1.0.1 が main に未反映」の警告を出し、リリース PR を作らない

5. 同期 PR をマージする。TAGPR が、`tagpr:minor` ラベル付きの v1.1.0 のリリース PR を作る

6. リリース PR をマージする。v1.1.0 のタグと、保守ブランチ `release/v1.1` ができる

ほかの場面（候補を時期を分けて出す、機能リリースの直後に1つ前の系統へ hotfix を出す、など）は、[検証した場面と PR](./scenarios) で、検証リポジトリの PR を追えます。

## 5. 実際のリポジトリで使うとき

### CI の起動（トークン） {#token}

検証リポジトリは `GITHUB_TOKEN` で push しています。`GITHUB_TOKEN` による push では `on: push` や `on: pull_request` のワークフローが起動しないので、push したあとに `gh workflow run ci.yaml --ref <ブランチ>` で CI を起動しています。

この方法には、次の制約があります。

- 起動した CI は、PR のチェックの欄に出ない。必須のチェックを設定していると、同期 PR がマージできない
- 自分の CI に置き換えるときも、`workflow_dispatch` で起動できるようにしておく必要がある

実際のリポジトリでは、GitHub App のトークンで push する形にするのがおすすめです。App のトークンによる push では、通常どおり `on: push` などのワークフローが起動します。この場合は、各ワークフローの `gh workflow run ci.yaml` の行が不要になります。

- App には、リポジトリの Contents と Pull requests の書き込み権限を付ける
- 修正にワークフローファイルの変更が含まれることがあるなら、Workflows の書き込み権限も付ける
- [`actions/create-github-app-token`](https://github.com/actions/create-github-app-token) でトークンを作り、`actions/checkout` の `token` と、`gh` に渡す `GH_TOKEN` に使う

::: info
検証リポジトリでは、App のトークンの形は試していません。上は GitHub の仕様にもとづく案です。
:::

### HOTFIX_RELEASE は main から実行する

保守ブランチにあるワークフローとスクリプトは、そのブランチを作った時点のままです。HOTFIX_RELEASE を直したら、main から実行すれば直したものが使われます。

### 保守ブランチを保護する場合

HOTFIX_RELEASE は、versionFile と CHANGELOG.md の更新を保守ブランチに直接 push します。TAGPR は、保守ブランチを REST API で作ります。`release/**` を ruleset で保護するなら、これらの push に使うトークン（App など）をバイパスの対象に加える必要があります。
