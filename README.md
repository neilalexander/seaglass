# Seaglass

Seaglass is a truly native macOS client for Matrix. It is written in Swift and
uses the Cocoa user interface framework.

![Screenshot of Seaglass](image.png)

## Building

Use Xcode 9.4 on macOS 10.13.

Right now Realm 3.6.0 is required - the Matrix iOS SDK requires the wrong
version. Clone it to a working directory of your choice:
```
mkdir WorkingDirectory
cd WorkingDirectory
git clone https://github.com/matrix-org/matrix-ios-sdk
```
Repair the `Podfile`:
```
cd matrix-ios-sdk
git checkout develop
sed -i '' "s/'Realm', '~> 3.3.2'/'Realm', '~> 3.6.0'/g" Podfile
cd ..
```
Clone the Seaglass repository and install dependencies:
```
git clone https://github.com/neilalexander/seaglass
cd seaglass
pod install
```
Open up `Seaglass.xcworkplace` and build!

## Things that work

- Logging in, as long as you are logging into `matrix.org`
- Seeing channels that you have already joined, completely without formatting
- Posting text to channels that you have already joined

## Things that don't work

- Just about everything else!

## Warning

At this stage it is early in development - pre-alpha even - and stands a good
chance of being buggy and unreliable. I'm also not a Swift expert and this code
might be awful. You've been warned. :-)
