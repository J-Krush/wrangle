#!/bin/bash
set -euo pipefail

# Build the Rust timeline engine and copy it into the app bundle.
# Called as an Xcode Run Script build phase.

ENGINE_DIR="$(cd "$(dirname "$0")/../engine" && pwd)"

# Xcode build phases don't inherit shell profile, so cargo may not be in PATH.
export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi
if ! command -v cargo &>/dev/null; then
    echo "error: Rust toolchain not found. Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Build based on Xcode configuration
if [ "${CONFIGURATION:-Debug}" = "Release" ]; then
    echo "Building wrangle-engine (release)..."
    cargo build --release --manifest-path "$ENGINE_DIR/Cargo.toml"
    BINARY="$ENGINE_DIR/target/release/wrangle-engine"
else
    echo "Building wrangle-engine (debug)..."
    cargo build --manifest-path "$ENGINE_DIR/Cargo.toml"
    BINARY="$ENGINE_DIR/target/debug/wrangle-engine"
fi

# Copy into app bundle
if [ -n "${BUILT_PRODUCTS_DIR:-}" ] && [ -n "${PRODUCT_NAME:-}" ]; then
    DEST="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources/wrangle-engine"
    mkdir -p "$(dirname "$DEST")"
    cp "$BINARY" "$DEST"
    # Sign the binary with the same identity as the app
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY:-"-"}" "$DEST"
    echo "Installed wrangle-engine to $DEST"
else
    echo "Built wrangle-engine at $BINARY (not in Xcode context, skipping bundle copy)"
fi
