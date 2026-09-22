# Fire TV display fix

Scripts for a Fire TV you own. This tree does not include a device address, ADB serial, account id, or sideload binary.

The useful fix: on a Toshiba/Insignia Fire TV Edition (model AFTDCT31, Fire OS 7 / Android 9), forcing a 4K UI makes some video apps draw only in the upper-left quarter of the screen. Set the UI back to 1920x1080 and reset density so the panel upscales a normal 1080p UI.

## Set up your own device

1. Install Android platform-tools and put `adb` on your PATH.
2. On the TV, turn on ADB debugging (Settings, Device & Software, About, Network, select until Developer Options appears, then ADB Debugging).
3. Connect with a host you choose. Do not commit that host.

```sh
adb connect 192.0.2.20:5555
./restore.sh 192.0.2.20:5555 examples/disable-packages.example.list
```

`192.0.2.20` is a documentation address. Replace it with your TV.

`restore.sh` will:

- install any `*.apk` you put in `apks/` (that directory is empty here on purpose)
- install `home-proxy/fast-home.apk` if you have built it
- disable packages from the list you pass
- set `wm size` to 1920x1080, reset density, shorten animations, and turn the screensaver off
- enable Home on Fire's accessibility service only if that package is already installed

`undo-everything.sh <adb-host> [disable-list] [--full]` puts those settings back.

`backup-state.sh <adb-host>` writes package lists under `state/`. That directory is gitignored.

## Apps you may sideload yourself

Obtain current builds from the projects that publish them, and confirm you may use them. This repo does not redistribute those APKs.

- FLauncher (`me.efesser.flauncher`) as an alternate launcher
- Home on Fire (`io.github.toolicious.homeonfire`) to send the Home button at FLauncher
- SmartTube (`org.smarttube.stable`) as an alternate YouTube client

Drop the files in `apks/` locally. They stay untracked.

## Fast Home

`home-proxy/` is a tiny HOME activity that launches FLauncher, including after boot. The package id in source is `com.example.firetvhome`. Change it before you ship a build.

```sh
export JAVA_HOME=/path/to/jdk-17
export ANDROID_HOME=/path/to/android-sdk
./home-proxy/build-and-install.sh 192.0.2.20:5555
```

The script creates a debug keystore under `signing/` (gitignored). Override the keystore password with `FIRETV_KEYSTORE_PASS`.

## License

MIT. See LICENSE.
