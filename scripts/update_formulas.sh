#!/bin/sh
# © 2025 D MALAM
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

# Error handler
die() {
    echo "ERROR: $1" >&2
    exit 1
}

# Fetch HTML once
echo "Fetching website HTML..."
html=$(curl -s "$BASE_URL") || die "Failed to fetch website"

# Extract versions
echo "Extracting versions..."
snapshot_version=$(echo "$html" | sed -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p' |
    grep -m1 "Release:" | sed 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')
release_version=$(echo "$html" | sed -n '/<h2>Download Release Build<\/h2>/,$ p' |
    grep -m1 "Release:" | sed 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')

[ -z "$snapshot_version" ] && die "Could not extract snapshot version"
[ -z "$release_version" ] && die "Could not extract release version"

echo "Found versions:"
echo "  Snapshot: $snapshot_version"
echo "  Release:  $release_version"

# Get URL for specific tool
get_tool_url() {
    section_type=$1
    platform_label=$2
    os=$3
    arch=$4
    tool=$5

    if [ "$section_type" = "Release" ]; then
        section_html=$(echo "$html" | sed -n '/<h2>Download Release Build<\/h2>/,$ p')
    else
        section_html=$(echo "$html" | sed -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p')
    fi

    # Debug output
    # echo "DEBUG: Looking for '$platform_label' in $os/$arch for $tool" >&2

    # Find URL by platform label and tool
    # Use fixed string matching for labels with spaces
    url=$(echo "$section_html" | grep -F -B30 -A100 "$platform_label" |
          tr '\n' ' ' |
          grep -o "href=\"[^\"]*/${os}/${arch}/[^\"]*${tool}\\.zip\"" |
          head -1 | sed 's/.*href="\([^"]*\)".*/\1/')

    echo "$url"
}

# Get SHA256 for URL
get_sha256() {
    url=$1
    if [ -n "$url" ]; then
        hash=$(curl -s "${BASE_URL}${url}.sha256" 2>/dev/null | awk '{print $1}')
        if [ -z "$hash" ]; then
            echo "WARNING: Could not fetch SHA256 for $url" >&2
        fi
        echo "$hash"
    fi
}

# Update formula file
update_formula() {
    file=$1
    build_type=$2  # "Release" or "Snapshot"
    new_version=$3

    [ ! -f "$file" ] && die "Formula file not found: $file"

    # Get current version
    current_version=$(grep 'version "' "$file" | sed 's/.*version "\([^"]*\)".*/\1/')

    # Check if update needed
    urls_empty=$(grep -c 'url ""' "$file" || true)
    if [ -z "$current_version" ] || [ "$new_version" != "$current_version" ] || [ "$urls_empty" -gt 0 ]; then
        echo "Updating $file: '$current_version' -> '$new_version'"

        # Update version
        sed_inplace "s/version \".*\"/version \"$new_version\"/" "$file"

        # Define platforms and their labels
        # Format: os|arch|label
        # ORDER MATTERS: Must match the order in the .rb formula files!
        # macOS ARM, macOS Intel, Linux ARM, Linux Intel
        platforms="
macos|arm64|macOS (Apple Silicon/arm64)
macos|amd64|macOS (Intel/amd64)
linux|arm64|Linux (arm64v8)
linux|amd64|Linux (amd64)
"

        # Get line numbers for URLs and SHA256s
        url_lines=$(grep -n 'url "' "$file" | cut -d: -f1 | tr '\n' ' ')
        sha_lines=$(grep -n 'sha256 "' "$file" | cut -d: -f1 | tr '\n' ' ')

        # Convert to arrays (word splitting is intentional here)
        # shellcheck disable=SC2086
        set -- $url_lines
        url_nums="$*"
        # shellcheck disable=SC2086
        set -- $sha_lines
        sha_nums="$*"

        line_idx=1
        echo "  Fetching URLs and hashes..."
        errors=0

        # Process each platform and tool
        IFS='
'
        for platform in $platforms; do
            [ -z "$platform" ] && continue

            os=$(echo "$platform" | cut -d'|' -f1)
            arch=$(echo "$platform" | cut -d'|' -f2)
            label=$(echo "$platform" | cut -d'|' -f3-)

            # Process each tool (ffmpeg, ffprobe, ffplay)
            for tool in ffmpeg ffprobe ffplay; do
                # Get URL and hash
                url=$(get_tool_url "$build_type" "$label" "$os" "$arch" "$tool")

                # Get line numbers for this entry
                url_line=$(echo "$url_nums" | cut -d' ' -f$line_idx)
                sha_line=$(echo "$sha_nums" | cut -d' ' -f$line_idx)

                # Update URL and hash
                if [ -n "$url" ] && [ -n "$url_line" ] && [ "$url_line" -gt 0 ] 2>/dev/null; then
                    hash=$(get_sha256 "$url")
                    if [ -z "$hash" ]; then
                        echo "  ERROR: No SHA256 for $os $arch $tool" >&2
                        errors=$((errors + 1))
                    fi
                    sed_inplace "${url_line}s|url \".*\"|url \"${BASE_URL}${url}\"|" "$file"
                    [ -n "$sha_line" ] && [ "$sha_line" -gt 0 ] 2>/dev/null && sed_inplace "${sha_line}s|sha256 \".*\"|sha256 \"$hash\"|" "$file"
                elif [ -n "$url_line" ] && [ "$url_line" -gt 0 ] 2>/dev/null; then
                    echo "  ERROR: No URL found for $label ($os/$arch) $tool" >&2
                    errors=$((errors + 1))
                    sed_inplace "${url_line}s|url \".*\"|url \"\"|" "$file"
                    [ -n "$sha_line" ] && [ "$sha_line" -gt 0 ] 2>/dev/null && sed_inplace "${sha_line}s|sha256 \".*\"|sha256 \"\"|" "$file"
                fi

                line_idx=$((line_idx + 1))
            done
        done
        IFS=' '

        if [ $errors -gt 0 ]; then
            echo "  Updated with $errors errors"
            return 1
        else
            echo "  Updated successfully"
        fi
    else
        echo "No update needed for $file (version: $current_version)"
    fi
}

# Update both formulas
total_errors=0

if ! update_formula "Formula/ffmpeg-static.rb" "Release" "$release_version"; then
    total_errors=$((total_errors + 1))
fi

if ! update_formula "Formula/ffmpeg-static-snapshot.rb" "Snapshot" "$snapshot_version"; then
    total_errors=$((total_errors + 1))
fi

if [ $total_errors -gt 0 ]; then
    echo "Completed with errors!"
    exit 1
else
    echo "Done!"
fi
