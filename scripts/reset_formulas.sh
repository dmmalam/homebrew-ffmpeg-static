#!/bin/sh
# © 2025 D MALAM
# Reset formulas to empty state for testing

set -e

# Use gsed on macOS, sed elsewhere
if [ "$(uname)" = "Darwin" ]; then
    SED="gsed"
else
    SED="sed"
fi

echo "Resetting formulas to empty state..."

# Reset ffmpeg-static.rb
echo "  Resetting ffmpeg-static.rb..."
$SED -i 's/version ".*"/version ""/' Formula/ffmpeg-static.rb
$SED -i 's|url ".*"|url ""|g' Formula/ffmpeg-static.rb
$SED -i 's|sha256 ".*"|sha256 ""|g' Formula/ffmpeg-static.rb

# Reset ffmpeg-static-snapshot.rb
echo "  Resetting ffmpeg-static-snapshot.rb..."
$SED -i 's/version ".*"/version ""/' Formula/ffmpeg-static-snapshot.rb
$SED -i 's|url ".*"|url ""|g' Formula/ffmpeg-static-snapshot.rb
$SED -i 's|sha256 ".*"|sha256 ""|g' Formula/ffmpeg-static-snapshot.rb

echo "Done! Formulas have been reset."
echo ""
echo "Current state:"
echo "=============="
echo "ffmpeg-static.rb version: $(grep 'version "' Formula/ffmpeg-static.rb | sed 's/.*version "\([^"]*\)".*/\1/')"
echo "ffmpeg-static-snapshot.rb version: $(grep 'version "' Formula/ffmpeg-static-snapshot.rb | sed 's/.*version "\([^"]*\)".*/\1/')"
echo ""
echo "Run ./scripts/update_formulas.sh to populate them again."