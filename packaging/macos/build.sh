#!/usr/bin/env bash
# Build omiloc.app with the CLT Swift compiler and package it into a DMG.
# No Xcode required. Output: build/omiloc.app, build/omiloc.dmg
set -euo pipefail
cd "$(dirname "$0")"
APP=build/omiloc.app
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -swift-version 5 -target arm64-apple-macos13.0 -o "$APP/Contents/MacOS/omiloc" main.swift
cp Info.plist "$APP/Contents/"
cp ../../web-local/assets/omiloc.icns "$APP/Contents/Resources/omiloc.icns"
codesign --force --deep -s - "$APP"
STAGE=build/dmg-stage
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname omiloc -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov build/omiloc.dmg
hdiutil verify build/omiloc.dmg
