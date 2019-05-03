#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
my (@failed, @passed, @knownbad, @missing);
my $upstream = 0;
my $coverage = 0;

GetOptions(
	'upstream' => \$upstream,
	'coverage' => \$coverage
);

if ($coverage) { $ENV{SILE_COVERAGE} = 1}

my @specifics = @ARGV;

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
    my $actual = $_; $actual =~ s/\.sil$/\.actual/;
    if (!system("grep KNOWNBAD $_ >/dev/null")) {
      $knownbad = 1;
    }
    if (system("diff -".($knownbad?"q":"")."U0 $expectation $actual")) {
      if ($knownbad) { push @knownbad, $_; }
      else { push @failed, $_; }
    } else {
      if ($knownbad) { push @knownbad, $_; }
      else { push @passed, $_; }
    }
  } else {
    push @missing, $_;
  }
}
if (@passed){
  print "\n",color("green"), "Passing tests:",color("reset");
  print "\n • ",join(", ", @passed),"\n";
}
if (@failed) {
  print "\n",color("red"), "Failed tests:\n",color("reset");
  for (@failed) { print " • ",$_,"\n"}
}
if (@knownbad){
  print "\n",color("yellow"), "Known bad tests:",color("reset");
  print "\n • ",join(", ", @knownbad),"\n";
}
if (@missing){
  print "\n",color("cyan"),"Tests missing expectations:",color("reset");
  print "\n • ",join(", ", @missing),"\n";
}
if (@failed) {
	exit 1;
}
