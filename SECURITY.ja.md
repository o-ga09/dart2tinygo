# セキュリティポリシー

**Languages:** [English](./SECURITY.md) | 日本語

## 脆弱性の報告方法

`dart2tinygo` にセキュリティ上の脆弱性を見つけた場合、**公開の Issue は立てないでください。**

代わりに、このリポジトリの [GitHub Security Advisories](https://github.com/o-ga09/dart2tinygo/security/advisories/new) から非公開で報告してください。以下を含めていただけると助かります。

- 脆弱性の内容と想定される影響
- 再現手順（最小の Dart 入力、CLI コマンドなど）
- 検証したバージョン／コミット

報告を確認し、できるだけ早く対応します。プロジェクトが小さく初期段階のため、正式な対応期限（SLA）はまだありませんが、他の作業より優先して対応します。

## 対象範囲

このポリシーは `dart2tinygo` の CLI／変換エンジンおよび本リポジトリ内のパッケージ（`tinygo_annotations`、`tinygo_machine`）を対象とします。ボード固有のバインディングパッケージ（将来の `package:wio_terminal` など）は別リポジトリのため対象外です。
