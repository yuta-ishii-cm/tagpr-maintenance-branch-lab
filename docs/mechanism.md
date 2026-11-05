# ワークフローの中身

ワークフローは2つ、補助のスクリプトは2つです。

| ファイル | 起動 | 役割 |
| --- | --- | --- |
| [`.github/workflows/tagpr.yaml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/workflows/tagpr.yaml)（TAGPR） | main への push | 機能リリース。tagpr にガード・minor・古いリリース PR の Close・保守ブランチの作成を足したもの |
| [`.github/workflows/hotfix-release.yaml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/workflows/hotfix-release.yaml)（HOTFIX_RELEASE） | 手動（workflow_dispatch） | hotfix。保守ブランチ名を入力して実行する |
| [`.github/scripts/resolve-sync-conflicts.sh`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/scripts/resolve-sync-conflicts.sh) | 上の2つから呼ぶ | 同期のときの versionFile・CHANGELOG.md だけのコンフリクトを解消する |
| [`.github/scripts/refresh-sync-prs.sh`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/scripts/refresh-sync-prs.sh) | 上の2つから呼ぶ | 同期先の更新でコンフリクトした同期 PR を直す |

## TAGPR（main への push）

ジョブは3つです。

### tagpr ジョブ

1. Guard: tagpr を動かしてよいかを確かめる
   - 最新タグが main に取り込まれていない（同期 PR のマージ待ち）なら、警告を出してスキップ
   - main の versionFile が最新タグより古いなら、エラーを出してスキップ
   - どちらの場合も、ジョブ自体は成功させる（同じワークフローでほかの処理をしていても止めないため）
   - リポジトリの変数 `GUARD_DISABLED` を `true` にすると、ガードを外せる（調査用）

2. tagpr を実行する（リリース PR の作成・更新。リリース PR がマージされた直後なら、タグと GitHub Release の作成）

3. Mark release PR as minor: リリース PR に `tagpr:minor` ラベルが無ければ付ける

4. ラベルを付けたときは、`git checkout -f main` してから tagpr をもう一度実行する（ラベルは次の実行から読まれるため）

5. Close stale release PRs: 今のリリース PR 以外の、`tagpr` ラベル付きの PR を Close する

### refresh-sync ジョブ

main 向けに開いている同期 PR のうち、main の更新（機能リリースや別の同期 PR のマージ）でコンフリクトしたものを直します。中身は `refresh-sync-prs.sh main` です。

### open-maintenance-branch ジョブ

tagpr がタグ（vX.Y.0）を作ったときだけ動きます。

1. タグのコミットから `release/vX.Y` を作る（REST API）

2. 古い保守ブランチに向けて開いている PR を、新しい保守ブランチに付け替える

3. 付け替えた PR に新しい保守ブランチを取り込み（update-branch）、CI を起動する。取り込めなかったら、PR にコメントして人に回す

## HOTFIX_RELEASE（手動）

入力は保守ブランチ名（例: `release/v1.1`）だけです。Actions のページで「Use workflow from」は main のまま実行します。

1. Decide version: 次のバージョンを決める
   - 入力が `release/vX.Y` の形か
   - `vX.Y.*` のタグがあり、そのうち最新のもの（現在のバージョン）が保守ブランチに含まれているか
   - 現在のバージョンのあとに、リリースする変更があるか
   - 問題なければ、現在のバージョンの patch を上げる

2. Update versionFile and CHANGELOG: versionFile の現在のバージョンを次のバージョンに置き換え、CHANGELOG.md に節を足す（中身は GitHub の Release Notes の自動生成）。コミットとタグを保守ブランチに push する

3. Create GitHub Release: 前のタグとの差分で Release Notes を作る

4. Open sync pull requests: 自分より新しい保守ブランチと main に同期 PR を作る
   - 同期先にタグをマージする。versionFile と CHANGELOG.md だけのコンフリクトなら `resolve-sync-conflicts.sh` で解消し、ほかのファイルがコンフリクトしたら、PR の本文にファイル名を書いて人に回す
   - 同じ系統の古い同期 PR は、新しい同期 PR に内容が含まれるので Close する

5. Close stale release PRs: main のリリース PR を Close する（最新タグが変わって古くなるため。同期 PR のマージ後に TAGPR が作り直す）

6. Refresh sync pull requests into this branch: 古い系統からこの保守ブランチに向けて開いている同期 PR を直す

7. Update fix candidates: この保守ブランチに向けて開いている修正候補に、今回のリリースを取り込む（update-branch）。取り込めなかったら、PR にコメントする

::: tip 補助のスクリプトは main のものを使う
保守ブランチにあるファイルは、そのブランチを作った時点のままです。HOTFIX_RELEASE は、スクリプトだけワークフローと同じ ref（main）から別にチェックアウトして使います。
:::

## 同期のときのコンフリクトの解消

`resolve-sync-conflicts.sh` は、versionFile と CHANGELOG.md だけがコンフリクトしたときに、次のように解消します。

- versionFile: 同期先と今回のリリースのうち、新しいバージョンのほうを残す。tagpr は versionFile の値を現在のバージョンとみなすので、古いほうに戻すと番号がずれる
- CHANGELOG.md: 同期先の内容に、同期先に無い節をすべて、バージョン順の位置（その節より古いバージョンの最初の節の手前）に差し込む

CHANGELOG.md を先頭に差し込むやり方や、今回の節だけを差し込むやり方で詰まった話は、[tagpr で詰まった点](./tagpr-pitfalls#changelog) にあります。

## 自動化の push と CI

`GITHUB_TOKEN` で push しても、`on: push` や `on: pull_request` のワークフローは起動しません（[GitHub のドキュメント](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow#triggering-a-workflow-from-a-workflow)）。

検証リポジトリでは、push したあとに `gh workflow run ci.yaml --ref <ブランチ>` で CI を起動しています。ただし、この方法で起動した CI は、PR のチェックの欄に出ません。必須のチェックを設定しているリポジトリでは、GitHub App のトークンで push する形に変えてください（[導入手順](./setup#token) を参照）。

## Release Notes から tagpr のリリース PR を外す

[`.github/release.yml`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/blob/main/.github/release.yml) で、`tagpr` ラベルの PR を Release Notes の自動生成から外しています。HOTFIX_RELEASE の CHANGELOG.md と GitHub Release に、リリース PR が載らないようにするためです。
