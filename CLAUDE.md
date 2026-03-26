# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Example repository demonstrating Percy visual testing with Maestro on BrowserStack. Contains a sample Android calculator app and Maestro flows that capture Percy screenshots.

## Repository Structure

- **`app/`** — Android calculator app (same app as example-percy-espresso-java)
- **`flows/`** — Maestro test flows
  - **`flows/percy/`** — Percy SDK files (copied from percy-maestro repo)
  - **`flows/screenshot-test.yaml`** — Main test flow demonstrating Percy integration
- **`resources/`** — Pre-built APK for quick start

## Build Commands

```bash
# Build the app APK
./gradlew assembleDebug

# Zip flows for BrowserStack upload
cd flows && zip -r ../Flows.zip . && cd ..
```

## Testing

Tests are Maestro flows (not Espresso). They run on BrowserStack App Automate via the Maestro v2 API. There are no local unit tests or instrumented tests in this repo.

## Percy Integration

The `flows/percy/` directory contains the Percy Maestro SDK (JS scripts and YAML sub-flows). These are copied from the [percy-maestro](https://github.com/percy/percy-maestro) repository. When updating Percy SDK files, copy from the source repo rather than editing in place.
