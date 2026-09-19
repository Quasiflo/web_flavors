# web_flavors
Flavor Support for Flutter Web

`flutter build web --flavor <name>` is rejected by the Flutter tool, so web
has no flavor concept. `web_flavors` works around that with a tiny wrapper
CLI: it fabricates `web/` from versioned sources, then forwards everything
else to `flutter`.

```sh
dart run web_flavors <flavor> -- <flutter args...>

dart run web_flavors dev -- build web
dart run web_flavors prod -- build web --wasm --release
dart run web_flavors dev -- run -d chrome
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

1. Deletes `web/` and recreates it from scratch, so stale files can never
   persist.
2. Copies `web-flavors/common/` into `web/` (when it exists).
3. Overlays `web-flavors/<flavor>/` on top; flavor files win on conflict.
4. Appends `--dart-define=WEB_APP_FLAVOR=<flavor>` and runs
   `flutter <flutter args...>`. The exit code is flutter's exit code.

Everything after `--` is forwarded verbatim; the wrapper never interprets
flutter flags. If your forwarded args already define `WEB_APP_FLAVOR`, the
wrapper errors out instead of silently desyncing `web/` from Dart code.

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

The wrapper injects `--dart-define=WEB_APP_FLAVOR=<flavor>` on every run, so
either option works. Use the first if you keep `web_flavors` a dev-only
dependency, the second for convenience:

```dart
// No dependency on this package.
const flavor = String.fromEnvironment('WEB_APP_FLAVOR');
```

```dart
import 'package:web_flavors/web_flavors.dart';

const flavor = WebAppFlavor.current; // e.g. 'dev', 'prod', '' when unset
```

## Why a wrapper instead of hooks?

Dart build hooks (`hook/build.dart`) cannot intercept or consume flutter's
`--flavor` flag, run at the wrong phase to mutate `web/` (which the Flutter
tool copies directly, outside the asset bundle), and are not invoked for web
builds at all. This is the same conclusion `flutter_rust_bridge` reached:
its native-assets hooks cover mobile/desktop, while web needs an explicit
`build-web` step outside `flutter`. See
[flutter/flutter#138992](https://github.com/flutter/flutter/issues/138992).
