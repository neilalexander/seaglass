# Seaglass
[![Build Status](https://travis-ci.org/neilalexander/seaglass.svg?branch=master)](https://travis-ci.org/neilalexander/seaglass)
[![Latest Build](https://img.shields.io/badge/Download-Latest%20Build-green.svg)](https://bintray.com/neilalexander/Seaglass/Seaglass)

Seaglass is a truly native macOS client for Matrix. It is written in Swift and
uses the Cocoa user interface framework.

![Screenshot of Seaglass](image.png)

## Building

Use Xcode 9.4 on macOS 10.13. Seaglass may require macOS 10.13 as a result of
using auto-layout for some table views, which seems to have been introduced with
High Sierra. I hope to find an alternate way to relax this requirement.

Clone the Seaglass repository and install dependencies:
```
git clone https://github.com/neilalexander/seaglass
cd seaglass
pod install
```
Open up `Seaglass.xcworkspace` in Xcode and build!

## Things that work

- Logging in to a homeserver you are already registered with
- Seeing channels that you have already joined, completely without formatting
- Posting text to channels that you have already joined
- Changing some room settings (history visibility, join rules, name, topic, aliases)
- Message coalescing
- Some Markdown formatting support in channels
- End-to-end encryption in rooms you are already joined to

## Things that don't work

- Anything else that isn't listed above!

## Goals

- Ability to join, leave, create, modify rooms
- Notifications for direct messages, highlights, invites, etc.
- Better user interface for verifying E2E devices/users
- Look and feel like a first-class citizen on macOS

## Disclaimer

At this stage it is early in development and stands a good chance of being buggy
and unreliable. I'm also not a Swift expert - I only started using Swift three
or four days before my initial commit - and this code is probably awful. You've
been warned. :-)
