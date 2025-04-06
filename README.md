# pffs

Player for favorite songs(pffs) is a music player with a playlist system, that gives full control over playback(speed, order, clip) and sound(volume).
App is intended to run on Android, Linux and Windows and be as simple as possible.

## Screenshots

| ![playlist-mobile](./screenshots/playlist-mobile.png)  | ![fullplayer-mobile](./screenshots/fullplayer-mobile.png) | ![playlists-mobile](./screenshots/playlists-mobile.png) |
| ---------------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------- |


![desktop-fullplayer](./screenshots/desktop-fullplayer.png)
![desktop-playlist](./screenshots/desktop-playlist.png)

## Features

- track volume adjustment (optional: smooth switching)
- track ordering in a playlist
- track speed adjustment
- skipping parts of track

## Usage

1. Install app on your device
1. choose folder with music
1. create a playlist
1. copy folder to other device
1. go to item 1

## Tips

* To open the full screen player, click on the track name.
* To change the order of tracks in a playlist on Android, press and hold, then drag.
* To set image for a track, create file TrackName.png in the same folder.
* To set image for a playlist, create file PlaylistName.png in the same folder.
* To hide header bar on Linux(which is usually done by your window manager) execute pffs with "--no-bar" flag

## Installation

Builds are tested on:
- Windows 10
- Arch Linux btw (Kernel 6.12.10-arch1-1, mpv 1:0.39.0-4)
- Fedora Workstation 40 (Kernel 6.8.5-301.fc40.x86_64, mpv-libs 0.37.0-4.fc40)
- Android 14

### Windows
1. Download pffs-windows-bundle-***.zip
1. Unzip in your favorite folder
1. Run "pffs.exe"

### Linux
1. Download pffs-linux-bundle-***.tar.gz
1. Unpack to your favorite folder 
1. Install mpv
1. Run "pffs" inside this folder or add it to your PATH

### Android
1. Download pffs-***.apk
1. Install it
1. Run "pffs"

## Flutter doctor output

```bash
[✓] Flutter (Channel stable, 3.24.5, on Arch Linux 6.12.10-arch1-1, locale en_US.UTF-8)
    • Flutter version 3.24.5 on channel stable at /usr/bin/flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision dec2ee5c1f (3 months ago), 2024-11-13 11:13:06 -0800
    • Engine revision a18df97ca5
    • Dart version 3.5.4
    • DevTools version 2.37.3

[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0-rc3)
    • Android SDK at /home/oleg/Android/Sdk
    • Platform android-34, build-tools 34.0.0-rc3
    • Java binary at: /usr/lib/jvm/java-17-openjdk/bin/java
    • Java version OpenJDK Runtime Environment (build 17.0.14+7)
    • All Android licenses accepted.

[✗] Chrome - develop for the web (Cannot find Chrome executable at google-chrome)
    ! Cannot find Chrome. Try setting CHROME_EXECUTABLE to a Chrome executable.

[✓] Linux toolchain - develop for Linux desktop
    • clang version 19.1.7
    • cmake version 3.31.5
    • ninja version 1.12.1
    • pkg-config version 2.3.0

[✓] Android Studio (version 2024.2)
    • Android Studio at /opt/android-studio
    • Flutter plugin can be installed from:
      🔨 https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin can be installed from:
      🔨 https://plugins.jetbrains.com/plugin/6351-dart
    • Java version OpenJDK Runtime Environment (build 21.0.3+-12282718-b509.11)
```

## Build
```bash
flutter build linux
```

```bash
flutter build apk
```

```bash
flutter build windows
```

