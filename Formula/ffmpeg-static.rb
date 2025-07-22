# © 2025 D MALAM
class FfmpegStatic < Formula
  desc "Static FFmpeg builds from Martin Riedl"
  homepage "https://ffmpeg.martin-riedl.de/"
  version "7.1.1"
  license "GPL-2.0-or-later"

  on_macos do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1741000090_7.1.1/ffmpeg.zip"
      sha256 "e18c39a330ad783c33d6d7b47784e82a42f8acdbb497a1f73550f1bc0e830d44"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1741000090_7.1.1/ffprobe.zip"
        sha256 "4eeb4644703bed221eec72107fbe2cc1e1180a3605c53136866cf43886d0499a"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1741000090_7.1.1/ffplay.zip"
        sha256 "130783f3c40e8fda1e363993ea141c7645894783f1d619e2754ee415fed0e27c"
      end
    else
      url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1741001873_7.1.1/ffmpeg.zip"
      sha256 "fd05ab8709c015b0a1922c65623beb8cff7f964c1524d060531bbb7b213b4cd2"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1741001873_7.1.1/ffprobe.zip"
        sha256 "bfea765749e422cd4b3512f2e0528592611d4ddfe47b128bf88453322f9050b5"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1741001873_7.1.1/ffplay.zip"
        sha256 "ca14a3d3e41476ceb664cc6025b3cf101ce3a479d6bbcd3ae0514a399833dbd1"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1740999880_7.1.1/ffmpeg.zip"
      sha256 "9395ec1dabf824b9aa98c8e6b06152724080a3f07a940ecdc503149b295ad2ee"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1740999880_7.1.1/ffprobe.zip"
        sha256 "30730e50d6e6286142098db4ab7ac2e6c95646b51d3dedd4bc55426a4e079867"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1740999880_7.1.1/ffplay.zip"
        sha256 "d57b387fa503ff135d2ea0c8ac2366bed20c9845187a4055546a31b418f5cd47"
      end
    else
      url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1741000776_7.1.1/ffmpeg.zip"
      sha256 "aa1f954f92ab8672009113138943ebb904a3f3d73a6df3c765c968d3039ad257"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1741000776_7.1.1/ffprobe.zip"
        sha256 "fcfedd6dbecee527ff73c3e75017d4532084390b06d7ae8a91e610525d85e5d5"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1741000776_7.1.1/ffplay.zip"
        sha256 "324682916ced4f9ad6d5f602c3b19610dde80bc6d2016af14ba3039adbafc2b0"
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
