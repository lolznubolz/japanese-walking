#!/usr/bin/env python3
"""Adds required permissions and the Russian app name to AndroidManifest.xml.
Run from japanese_walking/ after `flutter create . --platforms=android`."""

PATH = "android/app/src/main/AndroidManifest.xml"

PERMS = """    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
"""

src = open(PATH).read()
if "BLUETOOTH_CONNECT" not in src:
    src = src.replace("<application", PERMS + "    <application", 1)
src = src.replace('android:label="japanese_walking"', 'android:label="Японская ходьба"')
open(PATH, "w").write(src)
print("AndroidManifest patched")
