#!/bin/sh
# Builds the release web bundle. Cloudflare's build image has Node but no
# Flutter, so fetch the pinned SDK when `flutter` is not already on PATH.
set -eu
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
if ! command -v flutter >/dev/null 2>&1; then
  sdk="${FLUTTER_SDK_DIR:-$HOME/.cache/flutter-sdk-$FLUTTER_VERSION}"
  if [ ! -x "$sdk/bin/flutter" ]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$sdk"
  fi
  PATH="$sdk/bin:$PATH"
  export PATH
  flutter config --no-analytics >/dev/null 2>&1 || true
fi
flutter --version
flutter build web --release --no-web-resources-cdn "$@"
