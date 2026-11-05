# 検証した場面と PR

検証リポジトリで試した場面と、そのときの PR・タグです。PR の番号から、そのときの動きを追えます。

::: warning ワークフローは検証しながら直している
前半の PR は、途中の版のワークフローで動いています。直した順番は、[`.github` のコミット履歴](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/commits/main/.github) で追えます。
:::

## 候補を複数並行させ、時期を分けて出す

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#2](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/2)・[#3](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/3)・[#8](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/8) | 修正候補 A・B・D を `release/v1.0` に向けて作り、1つずつマージして HOTFIX_RELEASE を実行 | 出した順に v1.0.1・v1.0.2・v1.0.3 |
| [#7](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/7) | 修正候補 C を `release/v1.0` に向けて作り、出さずに残した | 機能リリースのたびに `release/v1.1`・`release/v1.2` へ付け替わり、そのつど新しい保守ブランチが取り込まれた。最後は `release/v1.2` で v1.2.2 として出た |
| [#9](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/9) | 修正候補 E（保守ブランチとコンフリクトする） | リリースや付け替えのたびに「取り込めませんでした（コンフリクト）」とコメントされ、人に回る。今は `release/v1.3` 向け |

## 機能リリースと保守ブランチの作成

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#13](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/13) | v1.1.0 のリリース PR（`tagpr:minor`） | タグ v1.1.0 と `release/v1.1` ができた |
| [#22](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/22) | v1.2.0 のリリース PR | タグ v1.2.0 と `release/v1.2` ができた |
| [#38](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/38) | v1.3.0 のリリース PR | タグ v1.3.0 と `release/v1.3` ができた |
| [#1](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/1)・[#6](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/6)・[#11](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/11)・[#14](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/14) など | hotfix で最新タグが変わって古くなったリリース PR | 自動で Close された |

## 機能リリースの直後に、1つ前の系統へ hotfix を出す

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#15](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/15) | v1.1.0 のタグのあと、`release/v1.0` に修正 F | v1.0.4。`release/v1.1`（[#16](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/16)）と main（[#17](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/17)）に同期 PR |
| [#18](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/18) | 同期 PR をマージする前に、`release/v1.0` に修正 G | v1.0.5。古い同期 PR（#16・#17）は Close され、[#19](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/19)・[#20](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/20) に置き換わった。このとき v1.0.4 の節が抜けた（[詰まった点の6](./tagpr-pitfalls#changelog)） |
| [#24](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/24) | v1.2.0 のタグのあと、`release/v1.1` に修正 H | v1.1.2。`release/v1.2`（[#25](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/25)）と main（[#26](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/26)）に同期 PR。versionFile は、どちらも同期先の v1.2.0 が残った |

## versionFile のずれ

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#21](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/21)・[#23](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/23) | v1.1.1 の同期で、当時の自動解消が main の versionFile（v1.1.0）を残した | #23 で手で直した。以降、自動解消は新しいバージョンを残すようにし、versionFile が最新タグより古いときは TAGPR がエラーで止まるようにした |

## ワークフローファイルを含む修正

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#32](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/32) | `release/v1.2` に、`ci.yaml` を変更する修正 J | v1.2.3。main への同期 PR（[#34](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/34)）も作れた |
| [#35](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/35) | `release/v1.1` に、ワークフローファイルを追加する修正 K | v1.1.3。`release/v1.2`（[#36](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/36)）と main（[#37](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/37)）への同期 PR も作れた |

## 古くなった同期 PR と、リリース PR の Close

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#41](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/41) | `release/v1.2` に修正 X | v1.2.4。`release/v1.3`（[#42](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/42)）と main（[#43](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/43)）に同期 PR |
| [#44](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/44) | `release/v1.3` に修正 Y | v1.3.1。main への同期 PR（[#45](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/45)） |
| [`273439a`](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/commit/273439a) | main の CHANGELOG.md を手で直し、main 向けの同期 PR #45 をコンフリクトさせた | TAGPR（refresh-sync ジョブ）が #45 に main を取り込み直し、自動で解消した |
| [#46](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/46) | `release/v1.2` に修正 Z | v1.2.5。#42・#43 は Close され、[#47](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/47)・[#48](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/48) に置き換わった（v1.2.4 と v1.2.5 の節が両方入っている）。main のリリース PR（[#40](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/40)）は HOTFIX_RELEASE が Close した |

## CI の起動

| PR | 内容 | 結果 |
| --- | --- | --- |
| [#30](https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab/pull/30) | 修正候補 I。付け替えや取り込みのあとに、CI が起動するかを確かめた | `gh workflow run` で起動した CI は、正しいコミットで動いた。ただし、PR のチェックの欄には出ない |
