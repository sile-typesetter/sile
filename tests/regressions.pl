#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
my (@failed, @passed, @unsupported, @knownbad, @knownbadbutpassing, @missing);

my @specifics = @ARGV;

my $exit = 0;
for (@specifics ? @specifics : <tests/*.sil tests/*.xml>) {
    my $expectation = $_; $expectation =~ s/\.(sil|xml)$/\.expected/;
    my $actual = $_; $actual =~ s/\.(sil|xml)$/\.actual/;
    my ($unsupported, $knownbad);
    if (-f $expectation) {
        open my $exp, $expectation or die $!;
        my $firstline = <$exp>;
        if ($firstline =~ /OS=(?!$^O)/) {
            push @unsupported, $_;
            next;
        }
        # Run but don't fail on tests that exist but are known to fail
        if (!system("head -n1 $_ | grep -q KNOWNBAD")) {
            $knownbad = 1;
        }
        if (! -f $actual) {
            push @failed, $_;
        } elsif (!system("grep -qx 'UNSUPPORTED' $actual")) {
            $unsupported = 1;
        } elsif (!system("diff -".($knownbad?"q":"")."U0 $expectation $actual")) {
            if ($knownbad) { push @knownbadbutpassing, $_;  }
            else { push @passed, $_; }
        } elsif ($knownbad) {
            push @knownbad, $_;
        } elsif ($unsupported) {
            push @unsupported, $_;
        } else {
            push @failed, $_;
        }
    } else {
        push @missing, $_;
    }
}
if (@passed){
    print "\n", color("green"), "Passing tests:", color("reset"), "\n";
    for (@passed) { print "✔ ", $_, "\n"}
}
if (@missing){
    print "\n", color("cyan"), "Tests missing expectations:", color("reset"), "\n";
    for (@missing) { print "• ", $_, "\n"}
}
if (@unsupported){
    print "\n", color("magenta"), "Tests unsupported on this system:", color("reset"), "\n";
    for (@unsupported) { print "⚠ ", $_, "\n"}
}
if (@knownbad){
    print "\n", color("yellow"), "Known bad tests that fail:", color("reset"), "\n";
    for (@knownbad) { print "⚠ ", $_, "\n"}
}
if (@knownbadbutpassing){
    print "\n", color("bright_yellow"), "Known bad tests that pass:", color("reset"), "\n";
    for (@knownbadbutpassing) { print "❓ ", $_, "\n"}
}
if (@failed) {
    print "\n", color("red"), "Failed tests:", color("reset"), "\n";
    for (@failed) { print "❌ ", $_, "\n"}
    exit 1;
}
