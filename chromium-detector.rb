class ChromiumDetector < Formula
  desc "Command-line tool to detect and analyze Chromium-based applications on macOS"
  homepage "https://github.com/fzlzjerry/chromium-detector"
  url "https://github.com/fzlzjerry/chromium-detector/archive/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  version "1.0.0"
  
  depends_on :xcode => ["13.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "--configuration", "release", "--disable-sandbox"
    bin.install ".build/release/chromium-detector"
  end

  test do
    system "#{bin}/chromium-detector"
  end
end 