# リリース手順

**Languages:** [English](./releasing.md) | 日本語

バージョン管理は [tagpr](https://github.com/Songmu/tagpr)、pub.dev への公開は
GitHub Actions が行います。このリポジトリのパッケージはすべて**同一バージョン**
（lockstep）で、タグ `vX.Y.Z` ひとつで全 pubspec を上げます。

## 普段の流れ

1. これまで通り PR を `main` にマージする。
2. `tagpr.yml` が `release vX.Y.Z` という PR を作成（または更新）する。この PR は
   `.tagpr` に列挙した全 pubspec の `version:` を上げ、パッケージ間の依存制約を
   書き換え（`tool/sync_versions.dart`。`wio_terminal` → `tinygo_annotations: ^X.Y.Z`
   が壊れないように）、マージ済み PR から `CHANGELOG.md` を更新する。
3. デフォルトは **patch** 上げ。それ以上に上げたいときはリリース PR に
   `minor` / `major` ラベルを付ける（tagpr が再実行して PR を更新する）。
4. リリース PR をマージすると `vX.Y.Z` タグと GitHub Release が作られる。
5. タグ push で `publish.yml` が走り、依存順に
   `tinygo_annotations` → `tinygo_machine` → `wio_terminal` → `dart2tinygo` を公開する。

`CHANGELOG.md` はリポジトリルートに 1 つだけ置き、pub.dev はパッケージごとに
必要とするため `publish.yml` が公開前に各パッケージへコピーします。

## 初回だけ必要な設定（自動化できない部分）

### 1. 初回公開は手動

pub.dev の自動公開は既存パッケージにしか設定できないため、各パッケージの最初の
バージョンは手動で公開します。最初のリリース PR をマージした後（pubspec が
リリースバージョンになった状態で）、この順で：

```sh
dart pub get
for pkg in tinygo_annotations tinygo_machine wio_terminal dart2tinygo; do
  cp CHANGELOG.md packages/$pkg/CHANGELOG.md
  (cd packages/$pkg && dart pub publish)
done
```

### 2. pub.dev で自動公開を有効化

4 パッケージそれぞれの pub.dev **Admin** タブで
**Automated publishing → Publishing from GitHub Actions** を次の値で有効化：

- Repository: `o-ga09/dart2tinygo`
- Tag pattern: `v{{version}}`

`publish.yml` は、ジョブに `id-token: write` があるときに `dart-lang/setup-dart`
が発行する OIDC トークンで認証します。pub.dev の認証情報をリポジトリに置く必要は
ありません。

### 3. tagpr が PR を作れるようにする

デフォルトの `GITHUB_TOKEN` では、**Settings → Actions → General → Workflow
permissions → Allow GitHub Actions to create and approve pull requests** を
チェックするまで、ワークフローからの PR 作成は拒否されます
（"GitHub Actions is not permitted to create or approve pull requests"）。
次の手順の `TAGPR_GITHUB_TOKEN`（PAT）を使う場合はこの設定の影響を受けません。

### 4. タグで `publish.yml` を起動できるようにする

デフォルトの `GITHUB_TOKEN` で push されたタグでは GitHub はワークフローを起動
しません。このリポジトリ用の fine-grained personal access token を
**Contents: read/write**、**Pull requests: read/write** で作成し、リポジトリの
secret `TAGPR_GITHUB_TOKEN` として登録してください。未設定でも `tagpr.yml` は
`GITHUB_TOKEN` にフォールバックしてリリース PR は作れますが、その場合は
`publish.yml` を手動実行する必要があります（**Actions → Publish to pub.dev →
Run workflow** で ref にタグ `vX.Y.Z` を選ぶ。pub.dev はトークンの ref がタグ
パターンに一致するか検証します）。

## ローカルでの確認

```sh
dart pub get
dart analyze
(cd packages/dart2tinygo && dart test)
(cd packages/tinygo_machine && dart pub publish --dry-run)
(cd packages/wio_terminal && dart pub publish --dry-run)
dart tool/sync_versions.dart 0.2.0   # tagpr の postVersionCommand と同じ処理
```
