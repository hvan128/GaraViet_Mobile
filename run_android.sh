#!/bin/bash

# Set environment variables
export LANG=en_US.UTF-8
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$PATH:/Users/macos/flutter/bin"

# Android SDK paths (adjust if needed)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Change to project directory
cd /Users/macos/GaraViet_Mobile

# Check if Android device is connected
echo "Checking for Android devices..."
flutter devices

# Run Flutter on Android device
echo "Running Flutter on Android device..."
flutter run
