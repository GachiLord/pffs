# pffs

Player for favorite songs(pffs) is a music player with a playlist system, that gives full control over playback(speed, order, clip) and sound(volume).
App is intended to run on Android, Linux and Windows and be as simple as possible.

## Usage

1. Install app on your device
1. choose folder with music
1. create a playlist
1. copy folder to other device
1. go to item 1

## Features

- track volume adjustment (optional: smooth switching)
- track ordering in a playlist
- track speed adjustment (*not implemented)
- skipping parts of track (*not implemented)

## Current state

At this moment player is usable, but it has many unimplemented things and potential bugs.

### Android issues
On android(tested on Android 14) library must be located at "Android/data/com.gachilord.pffs/files" because of restrictions of the OS.
It is possible to copy files to that folder on a root device or using custom file manager.

### Linux issues
Nope(tested on Arch btw). Just install mpv and build the app.

### Windows issues
Nope

## Installation

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
1. Download android-***.apk
1. Install it
1. Run "pffs"

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

