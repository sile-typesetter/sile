#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
my (@failed, @passed);
my $regression = 0;
my $upstream = 0;

GetOptions(
	'regression' => \$regression,
	'upstream' => \$upstream
);

my @specifics = @ARGV;

if ($regression) {
	my $exit = 0;
	for (@specifics ? @specifics : <tests/*.sil>) {
		my $expectation = $_; $expectation =~ s/\.sil$/\.expected/;
		if (-f $expectation) {
			# Only run regression tests for upstream bugs if specifically asked
			if ($_ =~ /_upstream\.sil/) {
				next if !$upstream;
			# Only test OS specific regressions on their respective OSes
			} elsif ($_ =~ /_\w+\.sil/) {
				next if ($_ !~ /_$^O\.sil/) ;
			}
			print "### Regression testing $_\n";
			my $out = $_; $out =~ s/\.sil$/\.actual/;
			exit $? >> 8 if system qq{./sile -e 'require("core/debug-output")' $_ > $out};
			if (system("diff -U0 $expectation $out")) {
				push @failed, $_;
			} else { push @passed, $_ }
		}
	}
	print "\n",color("green"), "Passing tests:\n • ",join(", ", @passed),"\n";
	if (@failed) {
		print "\n",color("red"), "Failed tests: \n";
		for (@failed) { print " • ",$_,"\n"}
		print color("reset");
		exit 1;
	}
	print color("reset");
} else {
	for (<examples/*.sil>, "documentation/sile.sil") {
		next if /macros.sil/;
		print "### Compiling $_\n";
		exit $? >> 8 if system("./sile", $_);
	}
}
