# © 2025 D MALAM
class FfmpegStaticSnapshot < Formula
  desc "Static FFmpeg snapshot builds from Martin Riedl (daily builds)"
  homepage "https://ffmpeg.martin-riedl.de/"
  version "N-120333-gf944a70fcc"
  license "GPL-2.0-or-later"

  conflicts_with "ffmpeg", because: "both install ffmpeg binaries"
  conflicts_with "ffmpeg-static", because: "both install ffmpeg binaries"

  on_macos do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753118211_N-120333-gf944a70fcc/ffmpeg.zip"
      sha256 "132d9802acc3d28ae0afe13a62f720597946961faa13a438c386d6ea4e4c60ad"
      
      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753118211_N-120333-gf944a70fcc/ffprobe.zip"
        sha256 "312c4e750d8ee049a216d5bd7533a4840d09c36bce27386be05dc7be5711ba7e"
      end
      
      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/arm64/1753118211_N-120333-gf944a70fcc/ffplay.zip"
        sha256 "ce3808aac1ed2728035552b58583988ed8149c0f5407886e3265e6c83d39eaab"
      end
    else
      url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753124454_N-120333-gf944a70fcc/ffmpeg.zip"
      sha256 "f196a3449b3f3f05bc3ec5024907887b404c569eec44ac68b04c9dbcc415c7b7"
      
      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753124454_N-120333-gf944a70fcc/ffprobe.zip"
        sha256 "a82d31e52c424aa433a126f1cce2642855259429225a4a6af8ee9def7828fdfb"
      end
      
      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/macos/amd64/1753124454_N-120333-gf944a70fcc/ffplay.zip"
        sha256 "3a37fc74ecf9afedc5f729126f54b25a1f179025a3eca08793c70965d84d77ff"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753117677_N-120333-gf944a70fcc/ffmpeg.zip"
      sha256 "c564907b996b9cd5b688709a18c7c2a6e14fa42217d2dacd028b2d2c473828a3"
      
      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753117677_N-120333-gf944a70fcc/ffprobe.zip"
        sha256 "71f852485884b6bc9ec02a59632ceb238eebaa4278e28e69dc50492acbcdaf4d"
      end
      
      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/arm64/1753117677_N-120333-gf944a70fcc/ffplay.zip"
        sha256 "d602912743615f726ec7c68a9dbdcf825d7c04e7bf4ef983be6e4358c06f41c6"
      end
    else
      url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753118773_N-120333-gf944a70fcc/ffmpeg.zip"
      sha256 "1065eed63a9c7c52b1ed96048129021417053ceeabcd21175249dae162267dc0"
      
      resource "ffprobe" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753118773_N-120333-gf944a70fcc/ffprobe.zip"
        sha256 "7866eb6e0c22a59d2a6cf474333ccc04c758ea519daf50903e0bba28c7fe8072"
      end
      
      resource "ffplay" do
        url "https://ffmpeg.martin-riedl.de/download/linux/amd64/1753118773_N-120333-gf944a70fcc/ffplay.zip"
        sha256 "debf66fca3a4e6f5a7cbc245e7d5943c6a44dacdb581f0e12cb408595f20743a"
      end
    end
  end

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

      To build from source instead, reinstall with:
        brew install --build-from-source ffmpeg-static-snapshot
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

  # Build from source option
  option "with-build-from-source", "Build FFmpeg snapshot from source using Martin Riedl's build script"

  if build.with?("build-from-source")
    depends_on "gcc" => :build
    depends_on "curl" => :build
    depends_on "make" => :build
    depends_on "zip" => :build
    depends_on "rust" => :build
    depends_on "python@3" => :build

    def install
      # Clone build script
      system "git", "clone", "https://git.martin-riedl.de/ffmpeg/build-script.git"

      # Create build directory
      builddir = buildpath/"build"
      builddir.mkpath

      cd builddir do
        # Run build script with snapshot flag
        system "../build-script/build.sh", "-FFMPEG_SNAPSHOT=YES"

        # Install binaries from out directory
        bin.install "out/bin/ffmpeg"
        bin.install "out/bin/ffprobe" if File.exist?("out/bin/ffprobe")
        bin.install "out/bin/ffplay" if File.exist?("out/bin/ffplay")
      end
    end
  end
end
