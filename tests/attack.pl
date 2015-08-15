#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
my (@failed, @passed, @knownbad);
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
		my $knownbad;
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
			if (!system("grep KNOWNBAD $_ >/dev/null")) {
				$knownbad = 1;
			}
			exit $? >> 8 if system qq{./sile -e 'require("core/debug-output")' $_ > $out};
			if (system("diff -U0 $expectation $out")) {
				push ($knownbad ? \@knownbad : \@failed, $_);
			} else { push $knownbad ? \@failed: \@passed, $_ }
		}
	}
	print "\n",color("green"), "Passing tests:\n • ",join(", ", @passed),"\n";
	if (@knownbad){
		print "\n",color("yellow"), "Known bad tests:\n • ",join(", ", @knownbad),"\n";
	}
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
