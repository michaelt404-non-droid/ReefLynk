#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="$PATH:`pwd`/flutter/bin"
# Run build
flutter pub get
flutter build web
