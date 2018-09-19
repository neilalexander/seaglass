# Seaglass
[![Build Status](https://travis-ci.org/neilalexander/seaglass.svg?branch=master)](https://travis-ci.org/neilalexander/seaglass)
[![Download Latest Build](https://api.bintray.com/packages/neilalexander/Seaglass/Seaglass/images/download.svg)](https://bintray.com/neilalexander/Seaglass/Seaglass/_latestVersion#files)

Seaglass is a truly native macOS client for Matrix. It is written in Swift and
uses the Cocoa user interface framework.

![Screenshot of Seaglass](image.png)

## Pre-built binaries

Travis CI is used to build binaries from the GitHub repository. You can [find the latest build here](https://bintray.com/neilalexander/Seaglass/Seaglass/_latestVersion#files).

## Building from source

Use Xcode 9.4 or Xcode 10.0 on macOS 10.13. Seaglass may require macOS 10.13 as a
result of using auto-layout for some table views, which seems to have been introduced
with High Sierra. I hope to find an alternate way to relax this requirement.

If you do not already have CocoaPods installed, then install it:
```
sudo gem install cocoapods
```

Clone the Seaglass repository and install dependencies:
```
git clone https://github.com/neilalexander/seaglass
cd seaglass
pod install
```
Open up `Seaglass.xcworkspace` in Xcode and build!

## Current features

- Logging in to a homeserver you are already registered with
- Creating and leaving rooms and direct chats
- Joining and parting rooms
- Inviting users to rooms (through `/invite`)
- Emotes (using `/me`) 
- Message redaction
- Posting text to rooms with Markdown formatting
- Changing some room settings (history visibility, join rules, name, topic, aliases)
- Message coalescing
- End-to-end encryption
  - Enabling end-to-end encryption in rooms
  - Marking devices as verified or blacklisted
  - Exporting and importing encryption keys (compatible with Riot)
  - Requesting (and re-requesting) keys from other Matrix clients
  - Choosing whether to send encrypted messages to unverified devices
- Viewing inline images and stickers
- Links to non-image attachments

## Disclaimer

At this stage it is early in development and stands a good chance of being buggy
and unreliable. I'm also not a Swift expert - I only started using Swift three
or four days before my initial commit - and this code is probably awful. You've
been warned. :-)
