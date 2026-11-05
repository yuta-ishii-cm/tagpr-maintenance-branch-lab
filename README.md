# tagpr-maintenance-branch-lab

tagpr で機能リリース（main）を回しながら、前のバージョンへの hotfix を保守ブランチ `release/vX.Y` から出す運用の検証用リポジトリ。

考え方・ワークフローの中身・導入手順・検証した場面は、ドキュメントにまとめている。

https://yuta-ishii-cm.github.io/tagpr-maintenance-branch-lab/

## 構成

- `.tagpr`: tagpr の設定（main 専用）
- `.github/workflows/tagpr.yaml`: TAGPR。機能リリース（ガード・minor・古いリリースPRの Close・保守ブランチの作成）
- `.github/workflows/hotfix-release.yaml`: HOTFIX_RELEASE。保守ブランチからの hotfix リリースと同期PR
- `.github/scripts/`: 同期PRのコンフリクトの解消
- `.github/workflows/ci.yaml`: workflow_dispatch でも起動するダミーCI
- `deploy/{dev,pro}/image-tag.jsonnet`: tagpr の versionFile（ダミー）
- `app/*.txt`: PR で変更するダミーファイル
- `docs/`: ドキュメント（VitePress）。`.github/workflows/docs.yaml` で GitHub Pages に公開する
