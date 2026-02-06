#!/bin/bash
# Install the latest stable version of Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Run doctor to confirm Flutter installation
flutter doctor

# Run build
flutter pub get
flutter build web