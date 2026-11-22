# QDiskInfo
QDiskInfo is a frontend for smartctl (part of the smartmontools package). It provides a user experience similar to CrystalDiskInfo. It shows the SMART (Self-Monitoring, Analysis, and Reporting Technology) data of modern hard disk drives.

<img width="1052" height="950" alt="image" src="https://github.com/user-attachments/assets/65b33dc4-34ed-4579-bffd-62208142aa0c" />

The icon is a modified version of the KDE Partition Manager logo which is available under GPL-3.0+.

## Packages
[![Packaging status](https://repology.org/badge/vertical-allrepos/qdiskinfo.svg)](https://repology.org/project/qdiskinfo/versions)
<br>Other than those mentioned in the widget above, there is also:
 - A [Fedora Copr Repository](https://copr.fedorainfracloud.org/coprs/birkch/QDiskInfo)
 - A Flatpak is currently <span style="color:red">NOT</span> possible due to a [permission issue](https://github.com/flatpak/flatpak/issues/2452)
 - Binaries and Appimages that work on every distro can be found [here](https://github.com/edisionnano/QDiskInfo/releases/latest)

## Compiling and Installing
### Compilation and Runtime Dependencies
Debian and Debian-based distros (Ubuntu, Mint, Pop!_OS, etc.)
```sh
sudo apt install build-essential cmake git libgl1-mesa-dev libxkbcommon-dev qt6-base-dev qt6-tools-dev qt6-tools-dev-tools qt6-wayland smartmontools
```
Fedora and derivatives (Nobara Project, etc.)
```sh
sudo dnf install cmake git mesa-libGL-devel libxkbcommon-devel qt6-qtbase-devel qt6-qttools-devel qt6-qtwayland-devel smartmontools
```
Arch Linux (includes Manjaro, EndeavourOS. CachyOS, Garuda Linux, etc.)
```sh
sudo pacman -Syu base-devel cmake hicolor-icon-theme polkit qt6-base qt6-svg smartmontools
```
### Compilation Steps
First you will need to clone the repository and cd inside
```sh
git clone https://github.com/edisionnano/QDiskInfo.git && cd QDiskInfo
```
Then you must create a build directory and cd inside, you can name it `build`
```sh
mkdir build && cd build
```
After that use CMake to setup the project. Qt version can also be set to 5 (for example for Ubuntu), translations can also be disabled if you don't want to install the required tools package
```sh
cmake .. -DCMAKE_BUILD_TYPE:STRING=MinSizeRel -DQT_VERSION_MAJOR=6 -DENABLE_TRANSLATIONS=ON
```
Finally, compile the project with all the threads using
```sh
make -j$(nproc)
```
This will create a `QDiskInfo` binary on the build directory but you can also install it using
```sh
sudo make install
```
If you installed QDiskInfo on your system using `sudo make install` and wish to uninstall it then run
```sh
sudo xargs rm < install_manifest.txt
```
in your build directory. The `install_manifest.txt` file is generated after running `sudo make install` so if you no longer have it, you can install again and then uninstall.

## Localisation
Currently, QDiskInfo has support for the following languages:
- 🌐 English (C)
- 🇬🇷 Greek (el_GR)
- 🇪🇸 Spanish (es_ES)
- 🇧🇷 Brazilian Portuguese (pt_BR)
- 🇨🇳 Simplified Chinese (zh_CN)

You can translate QDiskInfo to your language very easily using [Crowdin](https://crowdin.com/project/qdiskinfo). If your language isn't available on Crowdin, feel free to create a new issue.
<br><br>Alternatively you can copy the qdiskinfo_en_US.ts, which can be found inside the translations folder, to the locale you want. For example to qdiskinfo_de_DE.ts for German. Then you can use the QT Linguist application to translate the strings, marking every finished one with a tick. Compile the project with `-DENABLE_TRANSLATIONS=ON` to test your translation.
<br>If your system language differs from the one you are translating to, you can use
```sh
LC_ALL=de_DE.UTF-8 ./QDiskInfo
```
to force the app to use the language of your choice.<br>
<br>If changes were made to the original strings and your Qt version is <6.7 you can use the `lupdate` command to update the .ts files, for example to update the German translation file from the project's root you would run
```sh
lupdate . -ts translations/qdiskinfo_de_DE.ts -noobsolete
```
For Qt >=6.7 this is done automatically when running `make`.

## Common Issues
### Icons are Missing
If you are using QDiskInfo outside KDE, the arrows on the navigation keys and some other icons may be missing. To fix this install the Qt6 Configuration Tool (qt6ct) and append `export QT_QPA_PLATFORMTHEME=qt6ct` to the file `/etc/environment`

## Using CrystalDiskInfo Anime Themes
The process is similar to the one above with a few changes:<br>
First run `./scripts/fetch-aoi-themes.sh` (or pass a local archive path `./scripts/fetch-aoi-themes.sh /path/to/CrystalDiskInfo9_9_5Aoi.zip`) to dynamically download and unpack the CrystalDiskInfo Aoi theme backgrounds, `theme.ini` files, and chibi status sprites into `./themes/` (alternatively, place CrystalDiskInfo Aoi theme directories into `./themes/`).<br>
Once you do that compile like above but when running CMake do this instead:
```sh
cmake .. -DCMAKE_BUILD_TYPE:STRING=MinSizeRel -DQT_VERSION_MAJOR=6 -DINCLUDE_OPTIONAL_RESOURCES=ON -DCHARACTER_IS_RIGHT=ON -DENABLE_TRANSLATIONS=ON
```
Regarding the `-DCHARACTER_IS_RIGHT` set it to ON for themes where the character is right (like Aoi) or OFF for most other themes.

## Debian Packaging & GitHub Releases
### Installing the `.deb` Package (Debian 13 / Trixie)
Download `qdiskinfo-aoi_<version>_amd64.deb` (or `arm64.deb`) from [GitHub Releases](https://github.com/weaponmasterjax/QDiskInfo-Aoi-Edition-Debian/releases) and install it with `apt` so runtime dependencies (`smartmontools`, `pkexec`, `qt6-wayland`, and Qt6 SVG plugins) are installed automatically:
```sh
sudo apt install ./qdiskinfo-aoi_<version>_amd64.deb
```
`qdiskinfo-aoi` provides/replaces Debian's `qdiskinfo` package and installs Aoi themes under `/usr/share/QDiskInfo/themes`.

### Automated CI Builds & Releases (GitHub Actions)
- **CI Builds (`.github/workflows/build.yaml`)**: Every push to `main`, pull request, or manual dispatch builds `.deb` (`amd64` / `arm64`), `.AppImage`, and standalone binaries on `debian:trixie`, verifies `.deb` installation, and uploads workflow artifacts.
- **Publishing a Release (`.github/workflows/release.yaml`)**: Push a version tag matching `v*`:
  ```sh
  git tag v0.4.1
  git push origin v0.4.1
  ```
  or trigger the **Release** workflow manually from the GitHub Actions tab (`workflow_dispatch` with `tag`, optional `prerelease` and `draft` flags). The workflow builds `.deb` and `.AppImage` (`.zsync`) packages for both `amd64`/`x86_64` and `arm64`/`aarch64`, generates `SHA256SUMS.txt`, and creates the GitHub Release.
- To package a `.deb` via CPack manually in a build environment, run `./scripts/build-deb.sh --fetch-themes` (or `cpack --config build/CPackConfig.cmake -G DEB`).
