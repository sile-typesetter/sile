for (<tests/*.sil>, <examples/*.sil>, "documentation/sile.sil") {
    next if /macros.sil/;
    print "### Compiling $_\n";
    exit $? if system("./sile", $_);
}
