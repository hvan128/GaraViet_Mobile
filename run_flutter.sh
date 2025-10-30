#!/bin/bash

# Set environment variables
export LANG=en_US.UTF-8
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$PATH:/Users/macos/flutter/bin"

# Change to project directory
cd /Users/macos/GaraViet_Mobile

# Run Flutter
flutter run -d "00008120-0014450C0E58201E"

