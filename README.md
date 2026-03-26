# example-percy-maestro

Example app demonstrating Percy's visual testing integration with [Maestro](https://maestro.mobile.dev/) on BrowserStack.

## Percy Maestro Tutorial

This tutorial walks through using Percy with Maestro flows for visual testing on BrowserStack App Automate. It assumes you're already familiar with Maestro and focuses on the Percy integration.

The tutorial also assumes you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) installed.

### Step 1

Clone the example application:

```bash
$ git clone https://github.com/percy/example-percy-maestro
$ cd example-percy-maestro
```

### Step 2 — Upload the app

We have provided a pre-built APK in the `resources/` folder that you can use to get started without building from source. If you want to build from source, see [Build from source](#build-from-source) below.

You will need a BrowserStack `username` and `access key`. To obtain your access credentials, [sign up](https://www.browserstack.com/users/sign_up) for a free trial or [purchase a plan](https://www.browserstack.com/pricing). Get your `username` and `access key` from the [profile](https://www.browserstack.com/accounts/profile) page.

Upload the app APK:

```bash
$ curl -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
    -X POST "https://api-cloud.browserstack.com/app-automate/maestro/v2/app" \
    -F "file=@resources/app-debug.apk"
```

Note the `app_url` (e.g. `bs://...`) from the response.

### Step 3 — Upload Maestro flows

Zip and upload the Maestro flows (including the Percy SDK files):

```bash
$ cd flows && zip -r ../Flows.zip . && cd ..
```

```bash
$ curl -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
    -X POST "https://api-cloud.browserstack.com/app-automate/maestro/v2/test-suite" \
    -F "file=@Flows.zip"
```

Note the `test_suite_url` (e.g. `bs://...`) from the response.

### Step 4 — Create a Percy project

Sign in to [Percy](https://percy.io) and create a new `app` type project. After you've created the project, you'll be shown a `PERCY_TOKEN` environment variable.

### Step 5 — Execute tests

Run the Maestro flows on BrowserStack with Percy enabled:

```bash
$ curl -u "$BROWSERSTACK_USERNAME:$BROWSERSTACK_ACCESS_KEY" \
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

Replace `<APP_URL>`, `<TEST_SUITE_URL>`, and `<PERCY_TOKEN>` with the values from previous steps.

This will run the Maestro flows, which interact with the calculator app and capture Percy screenshots. The screenshots will be uploaded to Percy for comparison.

You can view the screenshots in Percy now if you want, but there will be no visual comparisons yet since this is the first build.

### Step 6 — Make a visual change

Modify `flows/screenshot-test.yaml` to change the test behavior. For example, change the single digit test to press "2" instead of "1":

```yaml
# Test 1: Single digit input
- tapOn: "2"
```

Re-zip and re-upload the flows (Step 3), then run again (Step 5).

### Step 7 — Review visual diffs

Visit your project in Percy and you'll see a new build with visual comparisons between the two runs. Click on the build to see the original screenshots on the left and the new screenshots on the right.

Percy has highlighted what's changed visually in the app! Snapshots with the largest changes are shown first. You can click on the highlight to reveal the underlying screenshot.

### Finished!

From here, you can try making your own changes to the app and flows. Re-run the tests and you'll see any visual changes reflected in Percy.

## Build from source

If you'd like to build the APK yourself instead of using the pre-built one:

```bash
$ ./gradlew assembleDebug
```

The APK will be generated at `app/build/outputs/apk/debug/app-debug.apk`.

## Percy integration

The Percy SDK files in `flows/percy/` handle communication with the Percy CLI. They are copied from the [percy-maestro](https://github.com/percy/percy-maestro) repository.

The integration works as follows:

1. **`percy/flows/percy-init.yaml`** — Runs a healthcheck against the Percy CLI server to verify it's available. Sets a `percyEnabled` flag used by subsequent steps.
2. **`percy/flows/percy-screenshot.yaml`** — Takes a Maestro screenshot, then uploads it to the Percy CLI via multipart POST with device metadata.

To take a Percy screenshot in your own flows, include the Percy init at the start and call the screenshot sub-flow wherever you want a visual snapshot:

```yaml
- runFlow: percy/flows/percy-init.yaml

- runFlow:
    file: percy/flows/percy-screenshot.yaml
    env:
      SCREENSHOT_NAME: "My screenshot"
```

Device metadata is configured via environment variables in the flow header (`PERCY_DEVICE_NAME`, `PERCY_OS_VERSION`, `PERCY_SCREEN_WIDTH`, `PERCY_SCREEN_HEIGHT`, `PERCY_ORIENTATION`).
