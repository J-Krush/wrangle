# Pre-Launch Todo

Remaining tasks before Wrangle v1.0.5 ships as a paid direct-download product (pay-upfront, no trial).

---

## Licensing (LemonSqueezy)

- [x] Create LemonSqueezy store and product for Wrangle
- [x] Configure LemonSqueezy API endpoints in `LicenseManager.swift` (standard LS API URLs)
- [x] Update the "Buy License" link (`https://wrangleapp.dev/buy`) in `LicenseGateView.swift` and `LicenseSettingsView.swift`
- [x] Hard license gate — app requires valid key on launch (no trial, no dismiss)
- [ ] Test license activation, validation, and deactivation with a real key (test purchase)

## Update Endpoint

- [x] `version.json` at `Landing Page/public/api/version.json` with correct format
- [ ] Verify update checker works against the hosted endpoint after deploy

## Code Signing & Notarization

- [ ] Ensure "Developer ID Application" certificate is installed from developer.apple.com
- [ ] Store notary credentials in Keychain:
  ```bash
  xcrun notarytool store-credentials "wrangle-notary" \
    --apple-id YOUR_APPLE_ID \
    --team-id 3DEKQ7GUK6 \
    --password APP_SPECIFIC_PASSWORD
  ```
- [ ] Run `scripts/build-release.sh` and verify `spctl --assess` passes
- [ ] Run `scripts/create-dmg.sh` and verify the DMG mounts correctly with app + Applications alias

## Distribution

- [x] Landing page updated with pay-upfront model (buy button + download link)
- [x] `/buy` redirect configured to LemonSqueezy checkout in `astro.config.mjs`
- [x] DMG download URLs updated to `https://dl.wrangleapp.dev/Wrangle-1.0.5.dmg`
- [ ] Upload notarized DMG to Cloudflare R2 at `https://dl.wrangleapp.dev/Wrangle-1.0.5.dmg`
- [ ] Deploy landing page to hosting
- [ ] Verify `wrangleapp.dev` loads correctly
- [ ] Verify `wrangleapp.dev/buy` redirects to LemonSqueezy checkout
- [ ] Verify download link downloads the DMG

## Final QA (End-to-End Smoke Test)

- [ ] Clear Keychain entry for `dev.wrangle.license`
- [ ] Launch freshly built app → license gate appears ("Welcome to Wrangle")
- [ ] Cannot dismiss without a key (no close button, no "continue" option)
- [ ] Enter a valid test key → Activate → gate disappears → app fully usable
- [ ] Settings → License shows "Licensed" with customer name
- [ ] Deactivate → license gate reappears immediately
- [ ] Enter invalid key → shows error message, gate stays
- [ ] **About:** Wrangle menu → About Wrangle shows version 1.0.5
- [ ] **File associations:** Right-click a `.md` file → Open With → Wrangle appears
- [ ] **DMG:** Mounts with app + Applications alias, drag-to-install works
