# Releasing

**Languages:** English | [日本語](./releasing.ja.md)

Versions are managed by [tagpr](https://github.com/Songmu/tagpr) and packages
are published to pub.dev by GitHub Actions. All packages in this repository
share **one version** (lockstep): a single tag `vX.Y.Z` bumps every pubspec.

## Day-to-day flow

1. Merge PRs into `main` as usual.
2. `tagpr.yml` opens (or updates) a PR titled `release vX.Y.Z` that bumps
   `version:` in every pubspec listed in `.tagpr`, rewrites the constraints
   between our own packages (`tool/sync_versions.dart`, so
   `wio_terminal` → `tinygo_annotations: ^X.Y.Z` stays valid), and updates
   `CHANGELOG.md` from the merged PRs.
3. The default bump is **patch**. Add the `minor` or `major` label to the
   release PR to bump further (tagpr re-runs and updates it).
4. Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
5. The tag push runs `publish.yml`, which publishes, in dependency order,
   `tinygo_annotations` → `tinygo_machine` → `wio_terminal` → `dart2tinygo`.

`CHANGELOG.md` lives at the repository root; `publish.yml` copies it into each
package before publishing, since pub.dev expects one per package.

## One-time setup (cannot be automated)

### 1. First publish by hand

pub.dev only allows automated publishing for packages that already exist, so
the very first version of each package is published manually, in this order,
after merging the first release PR (so the pubspecs are at the release version):

```sh
dart pub get
for pkg in tinygo_annotations tinygo_machine wio_terminal dart2tinygo; do
  cp CHANGELOG.md packages/$pkg/CHANGELOG.md
  (cd packages/$pkg && dart pub publish)
done
```

### 2. Enable automated publishing on pub.dev

For each of the four packages, open **Admin** on pub.dev and under
**Automated publishing → Publishing from GitHub Actions** set:

- Repository: `o-ga09/dart2tinygo`
- Tag pattern: `v{{version}}`

`publish.yml` authenticates with the OIDC token that `dart-lang/setup-dart`
provisions when the job has `id-token: write`; no pub.dev credentials are
stored in the repository.

### 3. Let tagpr open pull requests

With the default `GITHUB_TOKEN`, GitHub refuses PR creation from workflows
("GitHub Actions is not permitted to create or approve pull requests") until
**Settings → Actions → General → Workflow permissions →
Allow GitHub Actions to create and approve pull requests** is checked. The
`TAGPR_GITHUB_TOKEN` PAT from the next step is not subject to this setting.

### 4. Let the tag trigger `publish.yml`

GitHub does not run workflows for tags pushed with the default `GITHUB_TOKEN`.
Create a fine-grained personal access token for this repository with
**Contents: read/write** and **Pull requests: read/write**, and add it as the
`TAGPR_GITHUB_TOKEN` repository secret. `tagpr.yml` falls back to
`GITHUB_TOKEN` without it — release PRs still work, but you then have to
publish by running `publish.yml` manually (**Actions → Publish to pub.dev →
Run workflow**, choosing the tag `vX.Y.Z` as the ref; pub.dev checks that the
token's ref matches the tag pattern).

## Local checks

```sh
dart pub get
dart analyze
(cd packages/dart2tinygo && dart test)
(cd packages/tinygo_machine && dart pub publish --dry-run)
(cd packages/wio_terminal && dart pub publish --dry-run)
dart tool/sync_versions.dart 0.2.0   # what tagpr's postVersionCommand does
```
