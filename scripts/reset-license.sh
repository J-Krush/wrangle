#!/bin/bash
# Removes all Wrangle license/trial data from the keychain and UserDefaults.
# Useful for testing activation flows from a clean state.

echo "Removing license key from keychain..."
security delete-generic-password -s "dev.wrangle.license" -a "license-key" 2>/dev/null && echo "  Removed." || echo "  Not found."

echo "Removing trial data from keychain..."
security delete-generic-password -s "dev.wrangle.trial" -a "trial-data" 2>/dev/null && echo "  Removed." || echo "  Not found."

echo "Removing instance ID from UserDefaults..."
defaults delete Wrangle LicenseManager.instanceID 2>/dev/null && echo "  Removed." || echo "  Not found."

echo "Done. Restart Wrangle to see the license gate."
