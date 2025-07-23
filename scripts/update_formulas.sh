#!/bin/sh
# © 2025 D MALAM
# shellcheck disable=SC2292,SC2312,SC2310
set -e

BASE_URL="https://ffmpeg.martin-riedl.de"

# Portable sed in-place editing
sed_inplace() {
  if [ "$(uname)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Fetch HTML
echo "Fetching website HTML..."
if ! html=$(curl -s "${BASE_URL}"); then
  echo "ERROR: Failed to fetch website" >&2
  exit 1
fi

# Extract versions
echo "Extracting versions..."
snapshot_version=$(echo "${html}" | sed -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p' |
  grep -m1 "Release:" | sed 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')
release_version=$(echo "${html}" | sed -n '/<h2>Download Release Build<\/h2>/,$ p' |
  grep -m1 "Release:" | sed 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')

if [ -z "${snapshot_version}" ]; then
  echo "ERROR: Could not extract snapshot version" >&2
  exit 1
fi
if [ -z "${release_version}" ]; then
  echo "ERROR: Could not extract release version" >&2
  exit 1
fi

echo "Found versions:"
echo "  Snapshot: ${snapshot_version}"
echo "  Release:  ${release_version}"

# Update formula
update_formula() {
  file=$1
  type=$2
  version=$3

  if [ ! -f "${file}" ]; then
    echo "ERROR: File not found: ${file}" >&2
    exit 1
  fi

  # Check current version for snapshot formula (which needs explicit version)
  is_snapshot=0
  if echo "${file}" | grep -q "snapshot"; then
    is_snapshot=1
  fi
  if [ "${is_snapshot}" -eq 1 ]; then
    current=$(grep 'version "' "${file}" | sed 's/.*version "\([^"]*\)".*/\1/')
    if [ "${version}" = "${current}" ] && ! grep -q 'url ""' "${file}"; then
      echo "No update needed for ${file} (version: ${current})"
      return 0
    fi
    echo "Updating ${file}: '${current}' -> '${version}'"
    sed_inplace "s/version \".*\"/version \"${version}\"/" "${file}"
  else
    # Regular formula - no version line needed (Homebrew auto-detects)
    if ! grep -q 'url ""' "${file}"; then
      echo "No update needed for ${file}"
      return 0
    fi
    echo "Updating ${file} with version: ${version}"
  fi

  # Extract section HTML
  if [ "${type}" = "Release" ]; then
    section=$(echo "${html}" | sed -n '/<h2>Download Release Build<\/h2>/,$ p')
  else
    section=$(echo "${html}" | sed -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p')
  fi

  echo "  Fetching URLs and hashes..."
  errors=0

  # Get line numbers for urls and sha256s
  url_lines=$(grep -n 'url "' "${file}" | cut -d: -f1)
  sha_lines=$(grep -n 'sha256 "' "${file}" | cut -d: -f1)

  # Process each platform/tool combination
  idx=0
  for p in "macos|arm64|macOS (Apple Silicon/arm64)" "macos|amd64|macOS (Intel/amd64)" "linux|arm64|Linux (arm64v8)" "linux|amd64|Linux (amd64)"
  do
    os=$(echo "${p}" | cut -d'|' -f1)
    arch=$(echo "${p}" | cut -d'|' -f2)
    label=$(echo "${p}" | cut -d'|' -f3-)

    for tool in ffmpeg ffprobe ffplay
    do
      idx=$((idx + 1))
      url_line=$(echo "${url_lines}" | sed -n "${idx}p")
      sha_line=$(echo "${sha_lines}" | sed -n "${idx}p")

      # Find URL using grep + sed approach for better compatibility
      url=$(echo "${section}" | grep -F "${label}" -A100 |
        grep -o "href=\"[^\"]*/${os}/${arch}/[^\"]*${tool}\.zip\"" |
        head -1 | sed 's/.*href="\([^"]*\)".*/\1/')

      if [ -n "${url}" ]; then
        hash_response=$(curl -s "${BASE_URL}${url}.sha256" 2>/dev/null || true)
        hash=""
        if [ -n "${hash_response}" ]; then
          hash=$(echo "${hash_response}" | head -1 | awk '{print $1}' | tr -d '\n')
        fi
        if [ -z "${hash}" ]; then
          echo "  ERROR: No SHA256 for ${url}" >&2
          errors=$((errors + 1))
        else
          # Update specific lines
          sed_inplace "${url_line}s|url \".*\"|url \"${BASE_URL}${url}\"|" "${file}"
          [ -n "${sha_line}" ] && sed_inplace "${sha_line}s|sha256 \".*\"|sha256 \"${hash}\"|" "${file}"
        fi
      else
        echo "  ERROR: No URL found for ${label} ${tool}" >&2
        errors=$((errors + 1))
      fi
    done
  done

  if [ "${errors}" -gt 0 ]; then
    echo "  Updated with ${errors} errors"
    return 1
  fi
  echo "  Updated successfully"
  return 0
}

# Update both formulas
errors=0
if ! update_formula "Formula/ffmpeg-static.rb" "Release" "${release_version}"; then
  errors=$((errors + 1))
fi
if ! update_formula "Formula/ffmpeg-static-snapshot.rb" "Snapshot" "${snapshot_version}"; then
  errors=$((errors + 1))
fi

if [ "${errors}" -gt 0 ]; then
  echo "Completed with errors!"
  exit 1
fi
echo "Done!"
