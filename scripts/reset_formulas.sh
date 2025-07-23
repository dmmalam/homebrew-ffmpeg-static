#!/bin/sh
# © 2025 D MALAM
# shellcheck disable=SC2292,SC2312
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
for formula in Formula/ffmpeg-static.rb Formula/ffmpeg-static-snapshot.rb
do
  echo "  Resetting ${formula}..."
  # Only reset version for snapshot formula
  is_snapshot=0
  if echo "${formula}" | grep -q "snapshot"; then
    is_snapshot=1
  fi
  if [ "${is_snapshot}" -eq 1 ]; then
    sed_inplace -e 's/version ".*"/version ""/' \
      -e 's|url ".*"|url ""|g' \
      -e 's|sha256 ".*"|sha256 ""|g' "${formula}"
  else
    # Regular formula - no version line
    sed_inplace -e 's|url ".*"|url ""|g' \
      -e 's|sha256 ".*"|sha256 ""|g' "${formula}"
  fi
done

echo "Done! Formulas have been reset."
echo ""
echo "Current state:"
echo "=============="
for formula in Formula/ffmpeg-static.rb Formula/ffmpeg-static-snapshot.rb
do
  name=$(basename "${formula}" .rb)
  echo "${name}: reset complete"
done
echo ""
echo "Run ./scripts/update_formulas.sh to populate them again."
