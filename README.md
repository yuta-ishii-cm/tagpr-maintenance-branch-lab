# tagpr-maintenance-branch-lab

tagpr を main（機能リリース）と保守ブランチ `release/vX.Y`（修正リリース）の2系統で動かす運用の検証用リポジトリ。

## 確かめること

- 修正候補を複数並行させ、別々のタイミングでリリースできるか（番号はリリース順に振られるか）
- 修正リリース後に、main への同期PRと他の修正候補への取り込みが自動で行われるか
- main のリリースPRが minor で作られ、保守ブランチの patch と番号がぶつからないか
- 機能リリース時に新しい保守ブランチが作られ、修正候補PRが付け替わるか
- 同期前の main・引退した保守ブランチで tagpr を動かしたときに何が起きるか（ガードの要否）
- GITHUB_TOKEN による push で CI が起動するか

## 構成

- `deploy/{dev,pro}/image-tag.jsonnet`: tagpr の versionFile
- `app/*.txt`: PR で変更するダミーファイル
- `.github/workflows/tagpr.yaml`: tagpr と同期・付け替えの自動化
- `.github/workflows/ci.yaml`: push で起動するダミーCI
