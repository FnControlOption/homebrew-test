class PkgConfig < Formula
  desc "Manage compile and link flags for libraries"
  homepage "https://freedesktop.org/wiki/Software/pkg-config/"
  url "https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
  mirror "http://fresh-center.net/linux/misc/pkg-config-0.29.2.tar.gz"
  sha256 "6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://pkg-config.freedesktop.org/releases/"
    regex(/href=.*?pkg-config[._-]v?(\d+(?:\.\d+)+)\./i)
  end

  # FIXME: The bottle is mistakenly considered relocatable on Linux.
  # See https://github.com/Homebrew/homebrew-core/pull/85032.
  pour_bottle? only_if: :default_prefix

  def install
    pc_path = %W[
      #{HOMEBREW_PREFIX}/lib/pkgconfig
      #{HOMEBREW_PREFIX}/share/pkgconfig
    ]
    pc_path << if OS.mac?
      pc_path << "/usr/local/lib/pkgconfig"
      pc_path << "/usr/lib/pkgconfig"
      "#{HOMEBREW_LIBRARY}/Homebrew/os/mac/pkgconfig/#{MacOS.version}"
    elsif OS.linux?
      "#{HOMEBREW_LIBRARY}/Homebrew/os/linux/pkgconfig"
    else
      "#{HOMEBREW_LIBRARY}/Homebrew/os/bsd/pkgconfig"
    end

    pc_path = pc_path.uniq.join(File::PATH_SEPARATOR)

    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--disable-host-tool",
                          "--with-internal-glib",
                          "--with-pc-path=#{pc_path}",
                          "--with-system-include-path=#{MacOS.sdk_path_if_needed if OS.mac?}/usr/include"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"foo.pc").write <<~EOS
      prefix=/usr
      exec_prefix=${prefix}
      includedir=${prefix}/include
      libdir=${exec_prefix}/lib

      Name: foo
      Description: The foo library
      Version: 1.0.0
      Cflags: -I${includedir}/foo
      Libs: -L${libdir} -lfoo
    EOS

    ENV["PKG_CONFIG_LIBDIR"] = testpath
    system bin/"pkg-config", "--validate", "foo"
    assert_equal "1.0.0\n", shell_output("#{bin}/pkg-config --modversion foo")
    assert_equal "-lfoo\n", shell_output("#{bin}/pkg-config --libs foo")
    assert_equal "-I/usr/include/foo\n", shell_output("#{bin}/pkg-config --cflags foo")
  end
end
