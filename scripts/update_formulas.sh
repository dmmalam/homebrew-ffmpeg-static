#!/bin/sh
# © 2025 D MALAM
# Update FFmpeg formulas by parsing website HTML

set -e

# Use gsed on macOS, sed elsewhere
if [ "$(uname)" = "Darwin" ]; then
    SED="gsed"
else
    SED="sed"
fi

# Base URL
BASE_URL="https://ffmpeg.martin-riedl.de"

# Fetch HTML once
echo "Fetching website HTML..."
html=$(curl -s "$BASE_URL")

# Extract versions
echo "Extracting versions..."
snapshot_version=$(echo "$html" | $SED -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p' | grep -m1 "Release:" | $SED 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')
release_version=$(echo "$html" | $SED -n '/<h2>Download Release Build<\/h2>/,$ p' | grep -m1 "Release:" | $SED 's/.*<b>Release: <\/b>\([^<]*\).*/\1/')

echo "Found versions:"
echo "  Snapshot: $snapshot_version"
echo "  Release:  $release_version"

# Function to extract URL for a specific platform
get_url() {
    local section="$1"  # "Snapshot" or "Release"
    local label="$2"    # Platform label to search for
    local os="$3"       # OS in URL (macos or linux)
    local arch="$4"     # Architecture in URL (arm64 or amd64)
    
    # Get the appropriate section
    if [ "$section" = "Release" ]; then
        section_html=$(echo "$html" | $SED -n '/<h2>Download Release Build<\/h2>/,$ p')
    else
        section_html=$(echo "$html" | $SED -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p')
    fi
    
    # Find the URL by looking for the platform label and then the ffmpeg.zip link
    # Use more context lines to catch zip files that appear later
    url=$(echo "$section_html" | grep -B30 -A50 "$label" | grep "/${os}/${arch}/.*ffmpeg\.zip\"" | head -1 | $SED 's/.*href="\([^"]*\)".*/\1/')
    
    echo "$url"
}

# Get SHA256 from website
get_sha256() {
    local url="$1"
    if [ -n "$url" ]; then
        hash=$(curl -s "${BASE_URL}${url}.sha256" 2>/dev/null | awk '{print $1}')
        echo "$hash"
    fi
}

# Get URL for specific tool (ffmpeg, ffprobe, ffplay)
get_tool_url() {
    local section="$1"  # "Snapshot" or "Release"
    local label="$2"    # Platform label to search for
    local os="$3"       # OS in URL (macos or linux)
    local arch="$4"     # Architecture in URL (arm64 or amd64)
    local tool="$5"     # Tool name (ffmpeg, ffprobe, ffplay)
    
    # Get the appropriate section
    if [ "$section" = "Release" ]; then
        section_html=$(echo "$html" | $SED -n '/<h2>Download Release Build<\/h2>/,$ p')
    else
        section_html=$(echo "$html" | $SED -n '/<h2>Download Snapshot Build<\/h2>/,/<h2>Download Release Build<\/h2>/p')
    fi
    
    # Find the URL by looking for the platform label and then the tool zip link
    # Use tr to join lines, then extract the href
    url=$(echo "$section_html" | grep -B30 -A100 "$label" | tr '\n' ' ' | grep -o "href=\"[^\"]*/${os}/${arch}/[^\"]*${tool}\\.zip\"" | head -1 | $SED 's/.*href="\([^"]*\)".*/\1/')
    
    echo "$url"
}

# Update formula file
update_formula() {
    local file="$1"
    local type="$2"  # "release" or "snapshot"
    local new_version="$3"
    
    # Get current version
    current_version=$(grep 'version "' "$file" | $SED 's/.*version "\([^"]*\)".*/\1/')
    
    # Check if update needed (version change or empty URLs)
    urls_empty=$(grep -c 'url ""' "$file" || true)
    if [ -z "$current_version" ] || [ "$new_version" != "$current_version" ] || [ "$urls_empty" -gt 0 ]; then
        echo "Updating $file: '$current_version' -> '$new_version'"
        
        # Get URLs for each platform
        if [ "$type" = "release" ]; then
            # FFmpeg URLs
            macos_arm_url=$(get_url "Release" "Apple Silicon" "macos" "arm64")
            macos_intel_url=$(get_url "Release" "Intel" "macos" "amd64")
            linux_arm_url=$(get_url "Release" "arm64v8" "linux" "arm64")
            linux_intel_url=$(get_url "Release" "Linux (amd64)" "linux" "amd64")
            
            # FFprobe URLs
            macos_arm_ffprobe_url=$(get_tool_url "Release" "Apple Silicon" "macos" "arm64" "ffprobe")
            macos_intel_ffprobe_url=$(get_tool_url "Release" "Intel" "macos" "amd64" "ffprobe")
            linux_arm_ffprobe_url=$(get_tool_url "Release" "arm64v8" "linux" "arm64" "ffprobe")
            linux_intel_ffprobe_url=$(get_tool_url "Release" "Linux (amd64)" "linux" "amd64" "ffprobe")
            
            # FFplay URLs
            macos_arm_ffplay_url=$(get_tool_url "Release" "Apple Silicon" "macos" "arm64" "ffplay")
            macos_intel_ffplay_url=$(get_tool_url "Release" "Intel" "macos" "amd64" "ffplay")
            linux_arm_ffplay_url=$(get_tool_url "Release" "arm64v8" "linux" "arm64" "ffplay")
            linux_intel_ffplay_url=$(get_tool_url "Release" "Linux (amd64)" "linux" "amd64" "ffplay")
        else
            # FFmpeg URLs
            macos_arm_url=$(get_url "Snapshot" "Apple Silicon" "macos" "arm64")
            macos_intel_url=$(get_url "Snapshot" "Intel" "macos" "amd64")
            linux_arm_url=$(get_url "Snapshot" "arm64v8" "linux" "arm64")
            linux_intel_url=$(get_url "Snapshot" "Linux (amd64)" "linux" "amd64")
            
            # FFprobe URLs
            macos_arm_ffprobe_url=$(get_tool_url "Snapshot" "Apple Silicon" "macos" "arm64" "ffprobe")
            macos_intel_ffprobe_url=$(get_tool_url "Snapshot" "Intel" "macos" "amd64" "ffprobe")
            linux_arm_ffprobe_url=$(get_tool_url "Snapshot" "arm64v8" "linux" "arm64" "ffprobe")
            linux_intel_ffprobe_url=$(get_tool_url "Snapshot" "Linux (amd64)" "linux" "amd64" "ffprobe")
            
            # FFplay URLs
            macos_arm_ffplay_url=$(get_tool_url "Snapshot" "Apple Silicon" "macos" "arm64" "ffplay")
            macos_intel_ffplay_url=$(get_tool_url "Snapshot" "Intel" "macos" "amd64" "ffplay")
            linux_arm_ffplay_url=$(get_tool_url "Snapshot" "arm64v8" "linux" "arm64" "ffplay")
            linux_intel_ffplay_url=$(get_tool_url "Snapshot" "Linux (amd64)" "linux" "amd64" "ffplay")
        fi
        
        # Debug output
        if [ -z "$macos_arm_url" ] && [ -z "$macos_intel_url" ] && [ -z "$linux_arm_url" ] && [ -z "$linux_intel_url" ]; then
            echo "  WARNING: No URLs found for $type build"
        fi
        
        # Convert to full URLs
        [ -n "$macos_arm_url" ] && macos_arm_full="${BASE_URL}${macos_arm_url}" || macos_arm_full=""
        [ -n "$macos_intel_url" ] && macos_intel_full="${BASE_URL}${macos_intel_url}" || macos_intel_full=""
        [ -n "$linux_arm_url" ] && linux_arm_full="${BASE_URL}${linux_arm_url}" || linux_arm_full=""
        [ -n "$linux_intel_url" ] && linux_intel_full="${BASE_URL}${linux_intel_url}" || linux_intel_full=""
        
        # Convert ffprobe URLs to full URLs
        [ -n "$macos_arm_ffprobe_url" ] && macos_arm_ffprobe_full="${BASE_URL}${macos_arm_ffprobe_url}" || macos_arm_ffprobe_full=""
        [ -n "$macos_intel_ffprobe_url" ] && macos_intel_ffprobe_full="${BASE_URL}${macos_intel_ffprobe_url}" || macos_intel_ffprobe_full=""
        [ -n "$linux_arm_ffprobe_url" ] && linux_arm_ffprobe_full="${BASE_URL}${linux_arm_ffprobe_url}" || linux_arm_ffprobe_full=""
        [ -n "$linux_intel_ffprobe_url" ] && linux_intel_ffprobe_full="${BASE_URL}${linux_intel_ffprobe_url}" || linux_intel_ffprobe_full=""
        
        # Convert ffplay URLs to full URLs
        [ -n "$macos_arm_ffplay_url" ] && macos_arm_ffplay_full="${BASE_URL}${macos_arm_ffplay_url}" || macos_arm_ffplay_full=""
        [ -n "$macos_intel_ffplay_url" ] && macos_intel_ffplay_full="${BASE_URL}${macos_intel_ffplay_url}" || macos_intel_ffplay_full=""
        [ -n "$linux_arm_ffplay_url" ] && linux_arm_ffplay_full="${BASE_URL}${linux_arm_ffplay_url}" || linux_arm_ffplay_full=""
        [ -n "$linux_intel_ffplay_url" ] && linux_intel_ffplay_full="${BASE_URL}${linux_intel_ffplay_url}" || linux_intel_ffplay_full=""
        
        # Get SHA256 hashes
        echo "  Fetching SHA256 hashes..."
        macos_arm_hash=$(get_sha256 "$macos_arm_url")
        macos_intel_hash=$(get_sha256 "$macos_intel_url")
        linux_arm_hash=$(get_sha256 "$linux_arm_url")
        linux_intel_hash=$(get_sha256 "$linux_intel_url")
        
        # Get ffprobe SHA256 hashes
        macos_arm_ffprobe_hash=$(get_sha256 "$macos_arm_ffprobe_url")
        macos_intel_ffprobe_hash=$(get_sha256 "$macos_intel_ffprobe_url")
        linux_arm_ffprobe_hash=$(get_sha256 "$linux_arm_ffprobe_url")
        linux_intel_ffprobe_hash=$(get_sha256 "$linux_intel_ffprobe_url")
        
        # Get ffplay SHA256 hashes
        macos_arm_ffplay_hash=$(get_sha256 "$macos_arm_ffplay_url")
        macos_intel_ffplay_hash=$(get_sha256 "$macos_intel_ffplay_url")
        linux_arm_ffplay_hash=$(get_sha256 "$linux_arm_ffplay_url")
        linux_intel_ffplay_hash=$(get_sha256 "$linux_intel_ffplay_url")
        
        # Update version
        $SED -i "s/version \".*\"/version \"$new_version\"/" "$file"
        
        # Get line numbers for all URL/hash pairs (main + resources)
        url_lines=$(grep -n "url \"" "$file" | cut -d: -f1)
        sha_lines=$(grep -n "sha256 \"" "$file" | cut -d: -f1)
        
        # Convert to arrays - now we have 12 URLs and 12 SHA256s (4 platforms x 3 tools)
        set -- $url_lines
        url1=$1; url2=$2; url3=$3; url4=$4; url5=$5; url6=$6; url7=$7; url8=$8; url9=$9
        shift 9
        url10=$1; url11=$2; url12=$3
        
        set -- $sha_lines
        sha1=$1; sha2=$2; sha3=$3; sha4=$4; sha5=$5; sha6=$6; sha7=$7; sha8=$8; sha9=$9
        shift 9
        sha10=$1; sha11=$2; sha12=$3
        
        # Update URLs and hashes
        # macOS ARM64 - ffmpeg
        $SED -i "${url1}s|url \".*\"|url \"$macos_arm_full\"|" "$file"
        $SED -i "${sha1}s|sha256 \".*\"|sha256 \"$macos_arm_hash\"|" "$file"
        
        # macOS ARM64 - ffprobe resource
        $SED -i "${url2}s|url \".*\"|url \"$macos_arm_ffprobe_full\"|" "$file"
        $SED -i "${sha2}s|sha256 \".*\"|sha256 \"$macos_arm_ffprobe_hash\"|" "$file"
        
        # macOS ARM64 - ffplay resource
        $SED -i "${url3}s|url \".*\"|url \"$macos_arm_ffplay_full\"|" "$file"
        $SED -i "${sha3}s|sha256 \".*\"|sha256 \"$macos_arm_ffplay_hash\"|" "$file"
        
        # macOS Intel - ffmpeg
        $SED -i "${url4}s|url \".*\"|url \"$macos_intel_full\"|" "$file"
        $SED -i "${sha4}s|sha256 \".*\"|sha256 \"$macos_intel_hash\"|" "$file"
        
        # macOS Intel - ffprobe resource
        $SED -i "${url5}s|url \".*\"|url \"$macos_intel_ffprobe_full\"|" "$file"
        $SED -i "${sha5}s|sha256 \".*\"|sha256 \"$macos_intel_ffprobe_hash\"|" "$file"
        
        # macOS Intel - ffplay resource
        $SED -i "${url6}s|url \".*\"|url \"$macos_intel_ffplay_full\"|" "$file"
        $SED -i "${sha6}s|sha256 \".*\"|sha256 \"$macos_intel_ffplay_hash\"|" "$file"
        
        # Linux ARM64 - ffmpeg
        $SED -i "${url7}s|url \".*\"|url \"$linux_arm_full\"|" "$file"
        $SED -i "${sha7}s|sha256 \".*\"|sha256 \"$linux_arm_hash\"|" "$file"
        
        # Linux ARM64 - ffprobe resource
        $SED -i "${url8}s|url \".*\"|url \"$linux_arm_ffprobe_full\"|" "$file"
        $SED -i "${sha8}s|sha256 \".*\"|sha256 \"$linux_arm_ffprobe_hash\"|" "$file"
        
        # Linux ARM64 - ffplay resource
        $SED -i "${url9}s|url \".*\"|url \"$linux_arm_ffplay_full\"|" "$file"
        $SED -i "${sha9}s|sha256 \".*\"|sha256 \"$linux_arm_ffplay_hash\"|" "$file"
        
        # Linux Intel - ffmpeg
        $SED -i "${url10}s|url \".*\"|url \"$linux_intel_full\"|" "$file"
        $SED -i "${sha10}s|sha256 \".*\"|sha256 \"$linux_intel_hash\"|" "$file"
        
        # Linux Intel - ffprobe resource
        $SED -i "${url11}s|url \".*\"|url \"$linux_intel_ffprobe_full\"|" "$file"
        $SED -i "${sha11}s|sha256 \".*\"|sha256 \"$linux_intel_ffprobe_hash\"|" "$file"
        
        # Linux Intel - ffplay resource
        $SED -i "${url12}s|url \".*\"|url \"$linux_intel_ffplay_full\"|" "$file"
        $SED -i "${sha12}s|sha256 \".*\"|sha256 \"$linux_intel_ffplay_hash\"|" "$file"
        
        echo "  Updated successfully"
    else
        echo "No update needed for $file (version: $current_version)"
    fi
}

# Update both formulas
update_formula "Formula/ffmpeg-static.rb" "release" "$release_version"
update_formula "Formula/ffmpeg-static-snapshot.rb" "snapshot" "$snapshot_version"

echo "Done!"