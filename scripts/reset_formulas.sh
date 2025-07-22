#!/bin/sh
# © 2025 D MALAM
set -e

# Portable sed in-place editing
sed_inplace() {
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

echo "Resetting formulas to empty state..."

# Reset both formula files
for formula in Formula/ffmpeg-static.rb Formula/ffmpeg-static-snapshot.rb; do
    echo "  Resetting $formula..."
    sed_inplace -e 's/version ".*"/version ""/' \
                -e 's|url ".*"|url ""|g' \
                -e 's|sha256 ".*"|sha256 ""|g' "$formula"
done

echo "Done! Formulas have been reset."
echo ""
echo "Current state:"
echo "=============="
for formula in Formula/ffmpeg-static.rb Formula/ffmpeg-static-snapshot.rb; do
    name=$(basename "$formula" .rb)
    version=$(grep 'version "' "$formula" | sed 's/.*version "\([^"]*\)".*/\1/')
    echo "$name version: $version"
done
echo ""
echo "Run ./scripts/update_formulas.sh to populate them again."