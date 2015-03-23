use strict; use warnings;
for (<tests/*.sil>, <examples/*.sil>, "documentation/sile.sil") {
    next if /macros.sil/;
    print "### Compiling $_\n";
    my $expectation = $_; $expectation =~ s/\.sil$/\.expected/;
    if (-f $expectation) {
        my $out = $_; $out =~ s/\.sil$/\.actual/;
        exit $? >> 8 if system qq{./sile -e 'require("core/debug-output")' $_ > $out};
        if (system("diff -u $expectation $out")) {
            print("\n\n<<< EXPECTED >>>\n"); system("cat $expectation");  
            print("\n\n<<< GOT >>>\n"); system("cat $out");  
        }
    } else {
        exit $? >> 8 if system("./sile", $_);
    }
}
