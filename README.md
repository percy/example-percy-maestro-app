# example-percy-maestro-app

Example app demonstrating [Percy](https://percy.io)'s visual testing integration with [Maestro](https://maestro.mobile.dev/) on BrowserStack, using the [`@percy/maestro-app`](https://github.com/percy/percy-maestro-app) SDK.

The repo ships **two flows**:

- `flows/screenshot.yaml` — baseline: launches the calculator and captures two snapshots.
- `flows/regions.yaml` — demonstrates Percy regions: one coordinate-based ignore region, one element-based ignore region.

Both flows target the bundled BrowserStack sample calculator (`com.sample.browserstack.samplecalculator`).

## Prerequisites

- Node.js 14+ and npm
- `zip` on your `PATH` (used by `npm run prepare-zip`)
- A [BrowserStack](https://www.browserstack.com/) account with App Automate access
- A [Percy](https://percy.io/) project of type **App** and its `PERCY_TOKEN`

## Tutorial

### Step 1 — Clone and install

```bash
git clone https://github.com/percy/example-percy-maestro-app
cd example-percy-maestro-app
npm install
```

`npm install` brings in `@percy/maestro-app` and `@percy/cli` (devDependencies).

### Step 2 — Upload the app

A pre-built APK ships in `resources/`. To build from source instead, see [Build from source](#build-from-source) below.

```bash
curl -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
  -X POST "https://api-cloud.browserstack.com/app-automate/maestro/v2/app" \
  -F "file=@resources/app-debug.apk"
```

Note the `app_url` (e.g. `bs://...`) from the response.

### Step 3 — Prepare and upload the flows zip

`prepare-zip` vendor-copies the SDK from `node_modules/@percy/maestro-app/percy` into `flows/percy/` and zips `flows/` into `Flows.zip`. This is the recommended **Mode B** workflow from the [SDK README](https://github.com/percy/percy-maestro-app#installation).

```bash
npm run prepare-zip
```

```bash
curl -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
  -X POST "https://api-cloud.browserstack.com/app-automate/maestro/v2/test-suite" \
  -F "file=@Flows.zip"
```

Note the `test_suite_url` (e.g. `bs://...`) from the response.

### Step 4 — Run the build with Percy enabled

```bash
curl -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
  -X POST "https://api-cloud.browserstack.com/app-automate/maestro/v2/android/build" \
  -H "Content-Type: application/json" \
  -d '{
    "app": "<APP_URL>",
    "testSuite": "<TEST_SUITE_URL>",
    "devices": ["Samsung Galaxy S22-13.0"],
    "project": "Percy Maestro Example",
    "percyOptions": {
      "enabled": true,
      "percyToken": "<PERCY_TOKEN>"
    }
  }'
```

Replace `<APP_URL>`, `<TEST_SUITE_URL>`, and `<PERCY_TOKEN>` with values from previous steps.

BrowserStack runs both `screenshot.yaml` and `regions.yaml` in this build. Percy CLI on the BS host receives the screenshots and uploads them to your Percy project — **4 snapshots total** (2 from each flow).

> **iOS:** trigger the iOS build endpoint instead and use `appPercy` in place of `percyOptions`. See the [SDK README's BrowserStack Integration](https://github.com/percy/percy-maestro-app#browserstack-integration) section for the iOS payload shape.

### Step 5 — Review the build

Open the Percy build URL from your project. The first build is the baseline. Modify a `tapOn:` step in either flow, re-run `npm run prepare-zip` and Step 3–4, and Percy will diff the new snapshots against the baseline.

For the regions flow, notice that changes inside the masked regions (status bar, calculator result display) are **not** flagged as diffs — that's the regions feature working.

## The two flows

### `flows/screenshot.yaml`

Captures two snapshots: the calculator launch screen and a screen after entering an arithmetic operation. No regions, no special configuration. This is the minimum integration shape.

### `flows/regions.yaml`

Captures two snapshots, each demonstrating one region type:

- **Coordinate region:** `top: 0, bottom: 50, left: 0, right: 1080` with `algorithm: "ignore"` — masks the device status bar.
- **Element region:** `element: { "resource-id": "com.sample.browserstack.samplecalculator:id/editText" }` with `algorithm: "ignore"` — masks the calculator's result display, whose value changes between runs.

### Selector caveat

The bundled calculator app has zero `android:contentDescription` attributes, so `resource-id` is the only stable selector available. Resource IDs survive into the build because `app/build.gradle` sets `minifyEnabled false`. If you adapt this demo to an app that ships R8/minified release builds, prefer `content-desc` selectors — see the SDK's [Release-build caveat (Android)](https://github.com/percy/percy-maestro-app#release-build-caveat-android) section.

## Project layout

```
example-percy-maestro-app/
├── package.json              ← devDeps: @percy/maestro-app + @percy/cli
├── scripts/
│   └── prepare-zip.sh        ← vendors the SDK from node_modules + zips flows/
├── flows/
│   ├── screenshot.yaml       ← baseline 2-snapshot flow
│   └── regions.yaml          ← coordinate + element regions demo
├── app/                      ← Android sample app source
├── resources/
│   └── app-debug.apk         ← pre-built sample APK
└── build.gradle, gradlew, …  ← Gradle infra (used only by Build from source)
```

After `npm run prepare-zip`, a `flows/percy/` directory is added (vendored from `node_modules/@percy/maestro-app/percy`). Both `flows/percy/` and `Flows.zip` are gitignored — they're build outputs, not source.

## Build from source

To build the APK yourself instead of using the pre-built one:

```bash
./gradlew assembleDebug
```

The APK lands at `app/build/outputs/apk/debug/app-debug.apk`.

## Troubleshooting

### `PERCY_SERVER` in the flow YAMLs

Each `runFlow:` env block sets `PERCY_SERVER: "http://127.0.0.1:48087"`. This is **device-specific** — `48087` is the per-session Percy CLI port that BrowserStack assigns for the Samsung Galaxy S22 device (formula: `4{device_port}` = `4` + `8087`). Different devices may map to a different port.

**Why we hardcode it:** the SDK's documented default `http://percy.cli:5338` doesn't reach the per-session CLI on current BrowserStack hosts (no listener on `5338`, only on the assigned `4{device_port}`). The `maestro_runner.rb` on the host injects `PERCY_SESSION_ID` into the maestro test command's env but does **not** inject `PERCY_SERVER`. Until that's fixed upstream, customers must point their flows at the correct per-session port.

**To find your device's port** during a session:
- SSH to the BS host and run `lsof -nPi -sTCP:LISTEN | grep percy` while a session is active.
- Or read the per-session log filename `percy_cli.<session_id>_<port>.log` under `/var/log/browserstack/`.

If your `Flows.zip` upload succeeds and the BS build passes but Percy shows no snapshots ("Snapshot command was not called"), the most likely cause is a stale `PERCY_SERVER`.

### Snapshot names rejected

If you see `[percy] SCREENSHOT_NAME must match [a-zA-Z0-9_-]+` in the maestro log, your snapshot name has invalid characters. The Percy CLI relay enforces alphanumeric + underscore + hyphen only. Use `Calculator_launch` rather than `"Calculator launch"`. See the [SDK README's Snapshot naming section](https://github.com/percy/percy-maestro-app#snapshot-naming).

### Element-region resolver "multi-device-no-serial"

Element regions degrade gracefully (the snapshot still uploads, the region is silently skipped). This is a known cli_manager.rb gap on BrowserStack hosts — `ANDROID_SERIAL` is not injected into the Percy CLI's spawn env, so the resolver can't pick a device when multiple are connected. Coordinate regions are unaffected. Tracked separately as a `browserstack/mobile` follow-up.

## License

MIT
