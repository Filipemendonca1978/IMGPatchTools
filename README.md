# IMG Patch Tools
Patch image (.img) using sparse Android data image (.dat) in OTA zip with "BlockImageUpdate"
Patch other files (boot.img, firmwares) using patch file (.p) with "ApplyPatchfn"


## Requirements
For Building this tool you need :

* zlib
* libbz2
* openssl

It currently supports Linux x86/x64 & Termux & MacOS, Not tested on Windows.


## Usage
```
usage: ./BlockImageUpdate <system.img> <system.transfer.list> <system.new.dat> <system.patch.dat>
```
args:
- `<system.img>` = block device (or file) to modify in-place
- `<system.transfer.list>` = transfer list (blob) from OTA/rom zip
- `<system.new.dat>` = new data stream from OTA/rom zip
- `<system.patch.dat>` = patch stream from OTA/rom zip

```


after getting system.img or another firmware image
This is equals of previous functions on PC with this tools:
```
~$ ./BlockImageUpdate system.img system.transfer.list system.new.dat system.patch.dat
```
scriptpatcher.sh will generate all commands automatically from updater script so run it like:
```
~$ ./scriptpatcher.sh META-INF/com/google/android/updater-script > fullpatch.sh
```
check fullpatch.sh your self, you need to provide all images and files in correct name and patch as mentioned in mount and other commands of fullpatch.sh
