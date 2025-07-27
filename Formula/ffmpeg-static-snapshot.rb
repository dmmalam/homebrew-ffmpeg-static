# © 2025 D MALAM
class FfmpegStaticSnapshot < Formula
  desc "Static FFmpeg snapshot builds from Martin Riedl (daily builds)"
  homepage "https://ffmpeg.martin-riedl.de/"
  version "N-120362-g45810daf4d"
  license "GPL-2.0-or-later"

  on_macos do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753463856_N-120362-g45810daf4d/ffmpeg.zip"
      sha256 "68a9a84bcdb02dcca16848c38ce858645ef695b682a04619167f907d3572ae03"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753463856_N-120362-g45810daf4d/ffprobe.zip"
        sha256 "29865b40c950a677a391d398fdf02a21a227c5afbd6398358dda186dbbf5a38e"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753463856_N-120362-g45810daf4d/ffplay.zip"
        sha256 "85929ea773302671ab49be2e1b2db26570a7e0afa4b0b44aac412d83286204fc"
      end
    elsif Hardware::CPU.intel?
      url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753470000_N-120362-g45810daf4d/ffmpeg.zip"
      sha256 "94a024ae2826e5afb006828b2bbee06095d18bf949dda782a91f54e0a1019957"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753470000_N-120362-g45810daf4d/ffprobe.zip"
        sha256 "74eff0101b56a14fa7d4c19bdae180db0bab591600d0ef18a653238d24c34df5"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753470000_N-120362-g45810daf4d/ffplay.zip"
        sha256 "89b9f3bddc9c7700eb87f44c09225568373f35e1354b9074c6b3ab3efe606370"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753463227_N-120362-g45810daf4d/ffmpeg.zip"
      sha256 "9f60a4c013926a03ddb942e788b2c158d9e0acc73234627b2489ecc94a5b4fcb"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753463227_N-120362-g45810daf4d/ffprobe.zip"
        sha256 "16a0e1b99c5c061cfef7359a5b099ca31ae78cd89d77b264f94cde2b8489f866"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753463227_N-120362-g45810daf4d/ffplay.zip"
        sha256 "ea3375704d7c423ac8936d90e645553b2fc5c714aa7d29fd33c95fa38ae9b211"
      end
    elsif Hardware::CPU.intel?
      url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753464568_N-120362-g45810daf4d/ffmpeg.zip"
      sha256 "dda44dc98e970a0b4e0bc9ba71ecba2c5840eb52e4d8eaa0b5b5d96a7c127ba8"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753464568_N-120362-g45810daf4d/ffprobe.zip"
        sha256 "470cc8c437ec88f80f85c09f64b8b879a33f042572ca1e03be4c30bf0c4a674f"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753464568_N-120362-g45810daf4d/ffplay.zip"
        sha256 "58471432279c15df471f4b3724f35c451496871419efe682ed9b53ed87c756fe"
      end
    end
  end

  conflicts_with "ffmpeg", because: "both install ffmpeg binaries"
  conflicts_with "ffmpeg-static", because: "both install ffmpeg binaries"

  def install
    # Install main ffmpeg binary
    bin.install "ffmpeg"

    # Stage and install ffprobe
    resource("ffprobe").stage do
      bin.install "ffprobe"
    end

    # Stage and install ffplay
    resource("ffplay").stage do
      bin.install "ffplay"
    end

    # Set executable permissions
    bin.children.each { |f| f.chmod 0755 }
  end

  def caveats
    <<~EOS
      Static FFmpeg snapshot build installed. This is a pre-built daily snapshot from:
      https://ffmpeg.martin-riedl.de/

      This is a development build and may be unstable. For stable releases, use:
        brew install ffmpeg-static

    EOS
  end

  test do
    # Test ffmpeg runs
    system "#{bin}/ffmpeg", "-version"

    # Test ffprobe
    system "#{bin}/ffprobe", "-version"

    # Test ffplay
    system "#{bin}/ffplay", "-version"

    # Test basic conversion
    system "#{bin}/ffmpeg", "-f", "lavfi", "-i", "testsrc=duration=1:size=320x240:rate=1",
           "-f", "null", "-"
  end
end
