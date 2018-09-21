fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## Mac
### mac build_and_release
```
fastlane mac build_and_release
```
Build and release Seaglass, this is the lane you probably want to use
### mac build
```
fastlane mac build
```
Build Seaglass
### mac release
```
fastlane mac release
```
Release Seaglass on GitHub
### mac sparkle_add_version
```
fastlane mac sparkle_add_version
```
Updates sparkle RSS file

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
