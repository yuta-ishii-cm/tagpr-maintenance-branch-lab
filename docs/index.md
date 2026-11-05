---
layout: home

hero:
  name: tagpr 保守ブランチ運用
  text: 前のバージョンへの hotfix も、PR のマージとワークフローの実行だけで出す
  tagline: tagpr は main の機能リリース専用にし、保守ブランチ release/vX.Y からの hotfix は自前のワークフローでリリースする。その運用を検証したリポジトリの説明です
  actions:
    - theme: brand
      text: やりたいことと方針
      link: /concept
    - theme: alt
      text: 導入手順
      link: /setup
    - theme: alt
      text: GitHub
      link: https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab

features:
  - title: hotfix は3ステップ
    details: 修正 PR を保守ブランチにマージ → HOTFIX_RELEASE を実行 → デプロイ。versionFile・CHANGELOG.md・タグ・GitHub Release は自動で揃います
  - title: 番号の帯を分ける
    details: 機能リリースは minor、hotfix は patch を上げます。hotfix をいくつ出しても、次の機能リリースの番号は変わりません
  - title: 同期も自動
    details: hotfix の修正を新しい保守ブランチと main に取り込む同期 PR を自動で作ります。versionFile と CHANGELOG.md だけのコンフリクトは自動で解消します
---

## このサイトについて

通常リリースと hotfix が並行する案件で、hotfix の手順を減らすために考えた運用と、それを GitHub Actions で動かした検証の記録です。リリースの回し方は案件ごとに合う形が違うので、一案として読んでください。

- 検証に使ったリポジトリ: <https://github.com/yuta-ishii-cm/tagpr-maintenance-branch-lab>
- tagpr のバージョン: v1.20.2（ソースは v1.21.4 でも確認）
- 検証した時期: 2026年10月

読む順番の目安は次のとおりです。

1. [やりたいことと方針](./concept) で、何を解決したかったかをつかむ

2. [運用ルール](./rules) と [hotfix の流れ](./flow) で、人がやることを確認する

3. [ワークフローの中身](./mechanism) と [tagpr で詰まった点](./tagpr-pitfalls) で、自動化の中身を確認する

4. [導入手順](./setup) で、自分のリポジトリに入れて試す
