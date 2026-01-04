# BeatCheck

A fast and accurate BPM (Beats Per Minute) calculator for mobile devices. Tap along to any music or rhythm and BeatCheck instantly calculates the tempo.

## What is BeatCheck?

BeatCheck is a simple tap tempo tool designed for musicians, DJs, dancers, and music enthusiasts who need to quickly determine the BPM of a song or rhythm. Just tap along to the beat and the app does the rest.

## Features

- **Real-time BPM Calculation**: Get accurate BPM readings as you tap
- **Smart Tap Detection**: Automatically filters out accidental taps and outliers
- **Auto-reset**: Automatically resets after 2 seconds of inactivity
- **Wide BPM Range**: Supports tempos from 40 to 300 BPM
- **Fully Offline**: Works without internet connection
- **Clean Interface**: Simple, distraction-free design

## How to Use

1. Open the app
2. Tap the screen in rhythm with the music or beat
3. Watch the BPM calculate in real-time (accurate after about 5 taps)
4. Stop tapping to lock in the BPM, or wait 2 seconds to auto-reset

## Download

**Android**: Available on Google Play Store (coming soon)

**iOS**: Coming soon to the Apple App Store

## How It Works

BeatCheck uses an intelligent algorithm to calculate BPM:
- Records the timing of each tap with millisecond precision
- Calculates the intervals between consecutive taps
- Removes outliers that deviate significantly from the median
- Computes the average interval and converts to BPM
- Uses a rolling average of your last 5-8 taps for accuracy

## Requirements

- **Android**: Version 7.0 (API level 24) or higher
- **iOS**: Coming soon
- No internet connection required

## License

All Rights Reserved. Copyright © 2026

## About

BeatCheck is built with Flutter and currently available for Android, with iOS support coming soon.
