use strict; use warnings;
my $regression = ($ARGV[0] && $ARGV[0] =~ /--regression/i);
for (<tests/*.sil>, <examples/*.sil>, "documentation/sile.sil") {
    next if /macros.sil/;
    my $expectation = $_; $expectation =~ s/\.sil$/\.expected/;
    if (-f $expectation and $regression) {
        print "### Compiling $_\n";
        my $out = $_; $out =~ s/\.sil$/\.actual/;
        exit $? >> 8 if system qq{./sile -e 'require("core/debug-output")' $_ > $out};
        if (system("diff -u $expectation $out")) {
            print("\n\n<<< EXPECTED >>>\n"); system("cat $expectation");
            print("\n\n<<< GOT >>>\n"); system("cat $out");
            exit 1;
        }
    } elsif (!$regression) {
        print "### Compiling $_\n";
        exit $? >> 8 if system("./sile", $_);
    }
}
