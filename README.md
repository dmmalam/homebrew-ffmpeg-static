# homebrew-ffmpeg-static

Homebrew tap for [Martin Riedl's static FFmpeg builds](https://ffmpeg.martin-riedl.de/). Pre-compiled binaries for macOS and Linux (Intel/ARM).

## Features

- Pre-compiled static FFmpeg binaries
- Daily automated updates
- Platforms: macOS (Intel/ARM), Linux (Intel/ARM)
- Two channels: stable releases and daily snapshots

## Installation

```bash
brew tap dmmalam/ffmpeg-static
brew install ffmpeg-static              # Stable release
# Or
brew install ffmpeg-static-snapshot     # Daily snapshot
```

## Version Management

Daily GitHub Actions:
- Checks for new versions
- Updates formulas with latest URLs and SHA256 hashes
- Creates pull requests for changes

Pin a specific version: `brew pin ffmpeg-static`
Unpin: `brew unpin ffmpeg-static`

## Troubleshooting

### HTTP/2 Errors

If you encounter HTTP/2 stream errors during download:
```bash
brew install curl
export HOMEBREW_FORCE_BREWED_CURL=1
brew install ffmpeg-static
```

This forces Homebrew to use its own curl instead of older system curl.

## Conflicts

Conflicts with homebrew-core's `ffmpeg`. Uninstall it first:
```bash
brew uninstall ffmpeg
brew install ffmpeg-static
```

Snapshot conflicts with versioned, so only install either or.

## Included Codecs & Features

See Martins [ffmpeg build site](https://ffmpeg.martin-riedl.de)
Check features: `ffmpeg -version`

## Testing GitHub Actions Locally

Test workflows locally with [act](https://github.com/nektos/act) and podman:

```bash
# Test formula installation workflow
act -j test-bot -W .github/workflows/tests.yml

# Test version update workflow
act -j check-and-update -W .github/workflows/update-versions.yml

# Test with workflow_dispatch input
act workflow_dispatch -j check-and-update -W .github/workflows/update-versions.yml --input force_update=true

# Test PR publish workflow
act pull_request_target -j pr-pull -W .github/workflows/publish.yml
```

### Workflow Descriptions

- **tests.yml**: Runs formula syntax checks and installation tests across platforms
- **update-versions.yml**: Checks for new FFmpeg versions daily and creates PRs
- **publish.yml**: Pulls bottle artifacts from PRs when labeled with "pr-pull"

## License

MIT License for the tap. FFmpeg and included libraries have their own licenses.

## Credits

- [Martin Riedl's FFmpeg Builds](https://ffmpeg.martin-riedl.de/)
- [Build Script](https://git.martin-riedl.de/ffmpeg/build-script)
- [FFmpeg Project](https://ffmpeg.org/)

---
© 2025 D MALAM
