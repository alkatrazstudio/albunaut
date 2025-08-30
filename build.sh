#!/usr/bin/env bash
set -e
cd "$(dirname -- "${BASH_SOURCE[0]}")"

flutter --suppress-analytics config --enable-android
flutter --suppress-analytics clean
flutter --suppress-analytics pub get
dart --suppress-analytics run build_runner build --delete-conflicting-outputs
flutter --suppress-analytics analyze --no-pub
flutter --suppress-analytics build apk \
    --release \
    --dart-define=APP_BUILD_TIMESTAMP="$(date +%s)" \
    --dart-define=APP_GIT_HASH="$(git rev-parse HEAD)" \
    --split-debug-info=build/debug_info

echo "APK dir: $(pwd)/build/app/outputs/flutter-apk"
