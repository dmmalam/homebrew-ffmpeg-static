# © 2025 D MALAM
class FfmpegStaticSnapshot < Formula
  desc "Static FFmpeg snapshot builds from Martin Riedl (daily builds)"
  homepage "https://ffmpeg.martin-riedl.de/"
  version "N-120361-g829680f96a"
  license "GPL-2.0-or-later"

  on_macos do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753291476_N-120361-g829680f96a/ffmpeg.zip"
      sha256 "75fdc5d82400c677e0aa31511e398a02fabfd7ddb9797d8f53c632379831c51d"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753291476_N-120361-g829680f96a/ffprobe.zip"
        sha256 "ba10f1a818faab8ca71f532ee25e2703fc66d83443e6d863d13d0458f859de8d"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753291476_N-120361-g829680f96a/ffplay.zip"
        sha256 "ffd39b5387a8dc9b75b16d220cbe22313186196c75d7bdc845df1ac0676c4687"
      end
    elsif Hardware::CPU.intel?
      url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753297403_N-120361-g829680f96a/ffmpeg.zip"
      sha256 "3dc92cce994c08fbe6ef4495a8448545946a073b14fcaa1a364c51f8251e2b5f"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753297403_N-120361-g829680f96a/ffprobe.zip"
        sha256 "96df4229c306e71213ce8c7ee40e646d7655a3094c79857481ae230474d9214e"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753297403_N-120361-g829680f96a/ffplay.zip"
        sha256 "1a0fd19f79864346d11d35ca875add33f37a9d40085ce9a7faeb2bbdc048c195"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753290681_N-120361-g829680f96a/ffmpeg.zip"
      sha256 "29566d3d79c426b8c1cac01d80ff29a014b106ad5ba83d39187f6cbe88f97ada"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753290681_N-120361-g829680f96a/ffprobe.zip"
        sha256 "14e59698b5fdb74deebae39ec3e0c10ba6e5b64f6d46571dda7977adf214f190"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753290681_N-120361-g829680f96a/ffplay.zip"
        sha256 "6d8d069038a5e42cdcaa0f83dad465366973cb3caaf5bced96e2c5b30c990d92"
      end
    elsif Hardware::CPU.intel?
      url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753291682_N-120361-g829680f96a/ffmpeg.zip"
      sha256 "998edcf6b360b9410c19effe0fae142edd758f4507a3793c2982af0962ba4f50"

      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753291682_N-120361-g829680f96a/ffprobe.zip"
        sha256 "b7ee3c71ac7bd109df658f3705c3bb3804bf053e33d7531760a703f4671a3ffc"
      end

      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753291682_N-120361-g829680f96a/ffplay.zip"
        sha256 "0958070ed6a90c4039160f0f9baefcfd481301ba01600d3d64d30e0055430085"
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
