#!/usr/bin/env python3
"""Patches ios/Runner/Info.plist after `flutter create . --platforms=ios`:
 - Bluetooth usage descriptions (flutter_blue_plus needs them for HR straps/watches)
 - background modes (audio for the metronome, bluetooth-central for HR while screen is off)
 - Russian display name
Run from japanese_walking/ (mirrors tools/patch_android.py)."""
import re

PATH = "ios/Runner/Info.plist"

KEYS = """\t<key>NSBluetoothAlwaysUsageDescription</key>
\t<string>Подключение пульсометра или часов по Bluetooth, чтобы показывать пульс во время тренировки.</string>
\t<key>NSBluetoothPeripheralUsageDescription</key>
\t<string>Подключение пульсометра или часов по Bluetooth, чтобы показывать пульс во время тренировки.</string>
\t<key>UIBackgroundModes</key>
\t<array>
\t\t<string>audio</string>
\t\t<string>bluetooth-central</string>
\t</array>
"""

src = open(PATH).read()

# 1) Разрешения и фоновые режимы — один раз, сразу после первого <dict>.
if "NSBluetoothAlwaysUsageDescription" not in src:
    src = src.replace("<dict>", "<dict>\n" + KEYS, 1)

# 2) Русское имя на иконке.
if "CFBundleDisplayName" in src:
    src = re.sub(
        r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
        r"\1Японская ходьба\2",
        src,
    )
else:
    src = src.replace(
        "<dict>",
        "<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>Японская ходьба</string>",
        1,
    )

open(PATH, "w").write(src)
print("Info.plist patched (Bluetooth + background + RU name)")
