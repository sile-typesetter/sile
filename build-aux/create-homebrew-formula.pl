#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;
use Crypt::Digest::SHA256 qw(sha256_hex);
use Data::Dumper;

my @build_depends = qw(luarocks pkg-config);
my @homebrew_depends = qw(expat fontconfig harfbuzz icu4c libpng lua openssl@1.1 zlib);

my %not_rocks = map {$_ => 1} qw(lua bit32 compat53);
my %rocks = load_rockspec();

my %rock_url_templates = (
    cassowary   => "https://github.com/sile-typesetter/cassowary.lua/archive/vVERSION.tar.gz",
    linenoise   => "https://github.com/hoelzro/lua-linenoise/archive/VERSION.tar.gz",
    lpeg        => "http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-VERSION.tar.gz",
    lua_cliargs => "https://github.com/amireh/lua_cliargs/archive/vUNSTRIPPEDVERSION.tar.gz",
    "lua-zlib"  => "https://github.com/brimworks/lua-zlib/archive/vVERSION.tar.gz",
    luaexpat    => "https://github.com/tomasguisasola/luaexpat/archive/vVERSION.tar.gz",
    luaepnf     => "https://github.com/siffiejoe/lua-luaepnf/archive/vVERSION.tar.gz",
    luafilesystem => "https://github.com/keplerproject/luafilesystem/archive/vVERSIONUNDERSCORE.tar.gz",
    luarepl     => "https://github.com/hoelzro/lua-repl/archive/VERSION.tar.gz",
    luasocket   => "https://github.com/diegonehab/luasocket/archive/vVERSION.tar.gz",
    luasec      => "https://github.com/brunoos/luasec/archive/luasec-VERSION.tar.gz",
    luautf8     => "https://github.com/starwing/luautf8/archive/VERSION.tar.gz",
    penlight    => "https://github.com/Tieske/Penlight/archive/VERSION.tar.gz",
    vstruct     => "https://github.com/ToxicFrog/vstruct/archive/vVERSION.tar.gz",
    stdlib      => "https://github.com/lua-stdlib/lua-stdlib/archive/release-vVERSION.tar.gz"
);

my $version = `git describe --tags --abbrev=0`;
chomp $version;
$version =~ s/^v//;
print "Writing formula for SILE $version\n";

print "Fetching tarball...\n";
my $github_url = "https://github.com/sile-typesetter/sile/releases/download/v$version/sile-$version.tar.xz";
my $tarball =  get($github_url);
die "Couldn't download tarball - check $github_url !" unless defined $tarball;
my $shasum_tarball = sha256_hex($tarball);

open OUT, ">sile.rb" or die $!;

print OUT <<EOF;
class Sile < Formula
  desc "Modern typesetting system inspired by TeX"
  homepage "https://www.sile-typesetter.org"
  url "$github_url"
  sha256 "$shasum_tarball"

  head "https://github.com/sile-typesetter/sile.git", :shallow => false

  bottle do
    sha256 "f2fdd492e9272036fe2d35636d245a1ea05a0beebbb3a0a6b9b4019f36def3f3" => :catalina
    sha256 "ca6e60229ac5f6a6a9e0554c5fb1d2aecc3807556ae7b57943602cfc05061b20" => :mojave
    sha256 "d3b337dfa79cb2179426687064fb4eb5cc80cbc345ba6acdf0e885abd1360aa9" => :high_sierra
  end

  if build.head?
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

EOF

print OUT "  depends_on \"$_\" => :build\n" for @build_depends;
print OUT "  depends_on \"$_\"\n" for @homebrew_depends;

while (my ($rock, $version) = each %rocks) {
    if (!exists $rock_url_templates{$rock}) {
        print "WARNING: No URL template for rock $rock found in rockspec - should it be in the formula? If not, list it in \%not_rocks";
        print "Skipping $rock...\n";
        next;
    }
    my $url = $rock_url_templates{$rock};
    $url =~ s/UNSTRIPPEDVERSION/$version/g;
    my $underscore = $version; $underscore =~ s/[\.-]/_/g;
    $url =~ s/VERSIONUNDERSCORE/$underscore/g;
    $version =~ s/-\d+$//;
    $url =~ s/VERSION/$version/g;
    print("Fetching $rock $version from $url...\n");
    my $tarball = get($url);
    die "Can't load $url" unless $tarball;
    my $shasum = sha256_hex($tarball);
    print OUT <<EOF;
  resource "$rock" do
    url "$url"
    sha256 "$shasum"
  end

EOF
    delete $rock_url_templates{$rock};
}

if (keys %rock_url_templates) {
    print "WARNING: the following rocks were in the formula template, but not in the rockspec\n";
    print "(Maybe they should be added?)\n";
    print join " ", keys %rock_url_templates;
    print "\n";
}

while (<DATA>) { print OUT $_ };
close OUT;
print "Written successfully\n";

sub load_rockspec {
    open my $rockspec, "sile-dev-1.rockspec" or die "Can't load rockspec: $!";
    my %rocks;
    while (<$rockspec>) {
        if (/"([\w-]+) == ([\d\.-]+)"/) {
            $rocks{$1} = $2 unless $not_rocks{$1};
        }
    }
    return %rocks;
}

__DATA__

  def install
    luapath = libexec/"vendor"
    ENV["LUA_PATH"] = "#{luapath}/share/lua/5.3/?.lua;#{luapath}/share/lua/5.3/?/init.lua;#{luapath}/share/lua/5.3/lxp/?.lua"
    ENV["LUA_CPATH"] = "#{luapath}/lib/lua/5.3/?.so"

    resources.each do |r|
      r.stage do
        if r.name == "lua-zlib"
          # https://github.com/brimworks/lua-zlib/commit/08d6251700965
          mv "lua-zlib-1.1-0.rockspec", "lua-zlib-1.2-0.rockspec"
          system "luarocks", "make", "#{r.name}-#{r.version}-0.rockspec", "--tree=#{luapath}", "ZLIB_DIR=#{Formula["zlib"].opt_prefix}"
        elsif r.name == "luaexpat"
          system "luarocks", "build", r.name, "--tree=#{luapath}", "EXPAT_DIR=#{Formula["expat"].opt_prefix}"
        elsif r.name == "luasec"
          system "luarocks", "build", r.name, "--tree=#{luapath}", "OPENSSL_DIR=#{Formula["openssl@1.1"].opt_prefix}"
        else
          system "luarocks", "build", r.name, "--tree=#{luapath}"
        end
      end
    end

    system "./bootstrap.sh" if build.head?
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--with-system-luarocks",
                          "--with-lua=#{prefix}",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"

    (libexec/"bin").install bin/"sile"
    (bin/"sile").write <<~EOS
      #!/bin/bash
      export LUA_PATH="#{ENV["LUA_PATH"]};;"
      export LUA_CPATH="#{ENV["LUA_CPATH"]};;"
      "#{libexec}/bin/sile" "$@"
    EOS
  end

  test do
    assert_match "SILE #{version.to_s.match(/\d\.\d\.\d/)}", shell_output("#{bin}/sile --version")
  end
end
