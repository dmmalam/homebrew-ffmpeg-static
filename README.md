# homebrew-ffmpeg-static

Homebrew tap for [Martin Riedl's static FFmpeg builds](https://ffmpeg.martin-riedl.de/). Pre-compiled binaries for macOS and Linux (Intel/ARM).

## Features

- Pre-compiled static FFmpeg binaries
- Daily automated updates
- Platforms: macOS (Intel/ARM), Linux (Intel/ARM)
- Two channels: stable releases and daily snapshots
- Optional build from source

## Installation

```bash
brew tap dmmalam/ffmpeg-static
brew install ffmpeg-static              # Stable release
# Or
brew install ffmpeg-static-snapshot     # Daily snapshot
brew install --build-from-source ffmpeg-static  # Build from source
```

## Version Management

Daily GitHub Actions:
- Checks for new versions
- Updates formulas with latest URLs and SHA256 hashes
- Creates pull requests for changes

Pin a specific version: `brew pin ffmpeg-static`
Unpin: `brew unpin ffmpeg-static`

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

## License

MIT License for the tap. FFmpeg and included libraries have their own licenses.

## Credits

- [Martin Riedl's FFmpeg Builds](https://ffmpeg.martin-riedl.de/)
- [Build Script](https://git.martin-riedl.de/ffmpeg/build-script)
- [FFmpeg Project](https://ffmpeg.org/)

---
© 2025 D MALAM
