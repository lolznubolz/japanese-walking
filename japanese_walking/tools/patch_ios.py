#!/usr/bin/env python3
"""Adds required Info.plist keys (permissions, display name) for iOS.
Run from japanese_walking/ after `flutter create . --platforms=ios`."""

PATH = "ios/Runner/Info.plist"

KEYS = """	<key>CFBundleDisplayName</key>
	<string>WalkBeat</string>
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>Подключение пульсометра или часов для показа пульса во время ходьбы</string>
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>Подключение пульсометра или часов для показа пульса во время ходьбы</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
	</array>
"""

src = open(PATH).read()
if "NSBluetoothAlwaysUsageDescription" not in src:
    # insert just before the final </dict>
    idx = src.rfind("</dict>")
    src = src[:idx] + KEYS + src[idx:]
    open(PATH, "w").write(src)
    print("Info.plist patched")
else:
    print("Info.plist already patched")
