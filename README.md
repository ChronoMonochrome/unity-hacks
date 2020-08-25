# Unity hacks

This repository contains various hacks for Unity based android apps.

Usage: 
`bash script.sh App.apk`

Script does the following:
  - Replaces Unity boot.config in the given APK / XAPK file:
  - Replaces Unity library (if one is provided in the script)
  - Signes APK / XAPK
 
The aim of repository is to fix Unity app issues on unsupported (or poorly supported) devices.
Script doesn't modify any java code in the APK, so depending on app this might or might not work (or even make things even worse).
