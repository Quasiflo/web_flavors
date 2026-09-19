# web_flavors
Flavor Support for Flutter Web

`flutter build web --flavor <name>` is rejected by the Flutter tool, so web
has no flavor concept. `web_flavors` works around that with a tiny wrapper
CLI: it fabricates `web/` from versioned sources, then forwards everything
else to `flutter`.

```sh
dart run web_flavors [<flavor>] -- <flutter args...>

dart run web_flavors dev -- build web
dart run web_flavors -- build web
dart run web_flavors prod -- build web --wasm --release
dart run web_flavors dev -- run -d chrome
```

When `<flavor>` is omitted, the standard `flutter: default-flavor:` value
from the project's pubspec.yaml is used:

```yaml
flutter:
  default-flavor: prod
```

## How it works

Given a project layout of:

```text
web-flavors/common/       # files shared across all flavors
web-flavors/dev/          # dev-only files (index.html, manifest.json, icons, ...)
web-flavors/prod/         # prod-only files
web/                      # fabricated, never hand-edited
```

each invocation:

1. Resolves the flavor: the explicit `<flavor>` wins, otherwise the
   `flutter: default-flavor:` from pubspec.yaml, otherwise an error listing
   available flavors.
2. Deletes `web/` and recreates it from scratch, so stale files can never
   persist.
3. Copies `web-flavors/common/` into `web/` (when it exists).
4. Overlays `web-flavors/<flavor>/` on top; flavor files win on conflict.
5. Appends `--dart-define=WEB_APP_FLAVOR=<flavor>` and runs
   `flutter <flutter args...>`. The exit code is flutter's exit code.

Everything after `--` is forwarded verbatim; the wrapper never interprets
flutter flags. If your forwarded args already define `WEB_APP_FLAVOR`, the
wrapper errors out instead of silently desyncing `web/` from Dart code.
`--help` prints usage and `--version` prints the package version.

## ⚠️ `web/` is volatile

`web/` is deleted and re-fabricated on **every** run. Never edit it by hand:

- Keep it gitignored (`echo '/web/' >> .gitignore`).
- Edit `web-flavors/common/` and `web-flavors/<flavor>/` instead.
- Migrating an existing project: `git mv web web-flavors/common`, then move
  per-flavor files into `web-flavors/<flavor>/` and add `/web/` to
  `.gitignore`.
- `flutter create . --platforms web` regenerates into `web/`; merge anything
  you want to keep back into `web-flavors/` afterwards.

## Reading the flavor in app code

The wrapper injects `--dart-define=WEB_APP_FLAVOR=<flavor>` on every run.
Read it via the dedicated entry point (which exposes nothing else):

```dart
import 'package:web_flavors/flavor.dart';

const flavor = webAppFlavor; // e.g. 'dev', or null when unset
```

If you keep `web_flavors` a dev-only dependency, inline the lookup instead:

```dart
const raw = String.fromEnvironment('WEB_APP_FLAVOR');
const flavor = raw == '' ? null : raw;
```

## Why a wrapper instead of hooks?

Dart build hooks (`hook/build.dart`) cannot intercept or consume flutter's
`--flavor` flag, run at the wrong phase to mutate `web/` (which the Flutter
tool copies directly, outside the asset bundle), and are not invoked for web
builds at all. This is the same conclusion `flutter_rust_bridge` reached:
its native-assets hooks cover mobile/desktop, while web needs an explicit
`build-web` step outside `flutter`. See
[flutter/flutter#138992](https://github.com/flutter/flutter/issues/138992).
