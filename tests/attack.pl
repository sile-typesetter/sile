for (<tests/*.sil>, <examples/*.sil>, "documentation/sile.sil") {
    next if /macros.sil/;
    print "### Compiling $_\n";
    exit $? >> 8 if system("./sile", $_);
}
