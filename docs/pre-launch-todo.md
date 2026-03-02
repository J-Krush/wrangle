# Pre-Launch Todo

Remaining tasks before Wrangle v1.0 ships as a paid direct-download product.

---

## Licensing (LemonSqueezy)

- [ ] Create LemonSqueezy store and product for Wrangle
- [ ] Replace placeholder API URLs in `Wrangle/App/LicenseManager.swift` with actual LemonSqueezy endpoints
- [ ] Test license activation, validation, and deactivation with a real key
- [ ] Update the "Buy License" link (`https://wrangle.dev/buy`) in `LicenseGateView.swift` and `LicenseSettingsView.swift`

## Update Endpoint

- [ ] Host `version.json` at `https://wrangle.dev/api/version.json` with this format:
  ```json
  {
    "version": "1.0",
    "download_url": "https://wrangle.dev/download/Wrangle-1.0.dmg",
    "release_notes": "Initial release."
  }
  ```
- [ ] Test update checker against the hosted endpoint (set local version to `0.9` and verify the alert appears)

## Code Signing & Notarization

- [ ] Ensure "Developer ID Application" certificate is installed from developer.apple.com
- [ ] Store notary credentials in Keychain:
  ```bash
  xcrun notarytool store-credentials "wrangle-notary" \
    --apple-id YOUR_APPLE_ID \
    --team-id 3DEKQ7GUK6 \
    --password APP_SPECIFIC_PASSWORD
  ```
- [ ] Switch Release build signing identity from "Apple Development" to "Developer ID Application" in Xcode
- [ ] Run `scripts/build-release.sh` and verify `spctl --assess` passes
- [ ] Run `scripts/create-dmg.sh` and verify the DMG mounts correctly with app + Applications alias

## Xcode Project Cleanup

- [ ] Remove `Info.plist` from the "Copy Bundle Resources" build phase in Xcode (it's processed separately as `INFOPLIST_FILE`)

## Website & Distribution

- [ ] Set up `wrangle.dev` with download page, purchase flow, and version JSON endpoint
- [ ] Upload the notarized DMG to the download location referenced in `version.json`
- [ ] Verify end-to-end: fresh download -> mount DMG -> drag to Applications -> launch -> trial works -> purchase -> activate license

## Final QA

- [ ] **Settings:** Cmd+, opens Settings window with General and License tabs
- [ ] **Licensing:** Enter a test key -> validates against LemonSqueezy -> shows activated state. Deactivate -> shows trial/expired state.
- [ ] **Trial:** Fresh install shows 14-day trial. After expiry, dismissable nag appears on launch.
- [ ] **About:** Wrangle menu -> About Wrangle shows version, copyright, "Made by Krush" credits with website link
- [ ] **File associations:** Right-click a `.md` file in Finder -> Open With -> Wrangle appears. File opens in the app.
- [ ] **Update checker:** Host test JSON with a newer version -> app shows update alert with download link
- [ ] **Accessibility:** Turn on VoiceOver -> navigate sidebar and tabs -> all buttons announced with labels
- [ ] **DMG:** Mounts with app + Applications alias, drag-to-install works
