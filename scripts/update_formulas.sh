#!/bin/sh
# © 2025 D MALAM
# shellcheck disable=SC2292
set -e

BASE_URL="https://ffmpeg.martin-riedl.de"

# Portable sed in-place editing
sed_inplace() {
  if [ "$(uname)" = "Darwin" ]
  then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Fetch HTML
echo "Fetching website HTML..."
html=$(curl -s "${BASE_URL}") || {
  echo "ERROR: Failed to fetch website" >&2
  exit 1
}

# Extract versions
echo "Extracting versions..."
snapshot_version=$(echo "${html}" | sed -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p' |
  grep -m1 "Release:" | sed 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')
release_version=$(echo "${html}" | sed -n '/<h2>Download Release Build<\/h2>/,$ p' |
  grep -m1 "Release:" | sed 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')

[ -z "${snapshot_version}" ] && {
  echo "ERROR: Could not extract snapshot version" >&2
  exit 1
}
[ -z "${release_version}" ] && {
  echo "ERROR: Could not extract release version" >&2
  exit 1
}

echo "Found versions:"
echo "  Snapshot: ${snapshot_version}"
echo "  Release:  ${release_version}"

# Update formula
update_formula() {
  file=$1
  type=$2
  version=$3

  [ ! -f "${file}" ] && {
    echo "ERROR: File not found: ${file}" >&2
    exit 1
  }

  current=$(grep 'version "' "${file}" | sed 's/.*version "\([^"]*\)".*/\1/')

  if [ "${version}" = "${current}" ] && ! grep -q 'url ""' "${file}"
  then
    echo "No update needed for ${file} (version: ${current})"
    return 0
  fi

  echo "Updating ${file}: '${current}' -> '${version}'"
  sed_inplace "s/version \".*\"/version \"${version}\"/" "${file}"

  # Extract section HTML
  if [ "${type}" = "Release" ]
  then
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

      if [ -n "${url}" ]
      then
        hash=$(curl -s "${BASE_URL}${url}.sha256" 2>/dev/null | head -1 | awk '{print $1}' | tr -d '\n')
        if [ -z "${hash}" ]
        then
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

  [ "${errors}" -gt 0 ] && {
    echo "  Updated with ${errors} errors"
    return 1
  }
  echo "  Updated successfully"
  return 0
}

# Update both formulas
errors=0
update_formula "Formula/ffmpeg-static.rb" "Release" "${release_version}" || errors=$((errors + 1))
update_formula "Formula/ffmpeg-static-snapshot.rb" "Snapshot" "${snapshot_version}" || errors=$((errors + 1))

[ "${errors}" -gt 0 ] && {
  echo "Completed with errors!"
  exit 1
}
echo "Done!"
