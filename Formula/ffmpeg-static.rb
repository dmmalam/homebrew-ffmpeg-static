# © 2025 D MALAM
class FfmpegStatic < Formula
  desc "Static FFmpeg builds from Martin Riedl"
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
    else
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
    else
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
  conflicts_with "ffmpeg-static-snapshot", because: "both install ffmpeg binaries"

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
      Static FFmpeg build installed. This is a pre-built binary from:
      https://ffmpeg.martin-riedl.de/

    EOS
  end

  test do
    # Test ffmpeg version
    assert_match version.to_s, shell_output("#{bin}/ffmpeg -version")

    # Test ffprobe
    assert_match "ffprobe version", shell_output("#{bin}/ffprobe -version")

    # Test ffplay
    assert_match "ffplay version", shell_output("#{bin}/ffplay -version")

    # Test basic conversion
    system "#{bin}/ffmpeg", "-f", "lavfi", "-i", "testsrc=duration=1:size=320x240:rate=1",
           "-f", "null", "-"
  end
end
