# © 2025 D MALAM
class FfmpegStaticSnapshot < Formula
  desc "Static FFmpeg snapshot builds from Martin Riedl (daily builds)"
  homepage "https://ffmpeg.martin-riedl.de/"
  version ""
  license "GPL-2.0-or-later"

  on_macos do
    if Hardware::CPU.arm?
      url ""
      sha256 ""

      resource "ffprobe" do
        url ""
        sha256 ""
      end

      resource "ffplay" do
        url ""
        sha256 ""
      end
    elsif Hardware::CPU.intel?
      url ""
      sha256 ""

      resource "ffprobe" do
        url ""
        sha256 ""
      end

      resource "ffplay" do
        url ""
        sha256 ""
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url ""
      sha256 ""

      resource "ffprobe" do
        url ""
        sha256 ""
      end

      resource "ffplay" do
        url ""
        sha256 ""
      end
    elsif Hardware::CPU.intel?
      url ""
      sha256 ""

      resource "ffprobe" do
        url ""
        sha256 ""
      end

      resource "ffplay" do
        url ""
        sha256 ""
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
