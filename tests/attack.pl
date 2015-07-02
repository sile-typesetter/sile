#!/usr/bin/env perl

use strict;
use warnings;

my $regression = ($ARGV[0] && $ARGV[0] =~ /--regression/i);
if ($regression) {
	my $exit = 0;
	for (<tests/*.sil>) {
		my $expectation = $_; $expectation =~ s/\.sil$/\.expected/;
		if (-f $expectation) {
			# Only test OS specific regressions on their respective OSes
			next if ($_ =~ /_\w+\.sil/ && $_ !~ /_$^O\.sil/);
			print "### Regression testing $_\n";
			my $out = $_; $out =~ s/\.sil$/\.actual/;
			exit $? >> 8 if system qq{./sile -e 'require("core/debug-output")' $_ > $out};
			if (system("diff -U0 $expectation $out")) {
				$exit = 1;
			}
		}
	}
	exit $exit;
} else {
	for (<examples/*.sil>, "documentation/sile.sil") {
		next if /macros.sil/;
		print "### Compiling $_\n";
		exit $? >> 8 if system("./sile", $_);
	}
}
