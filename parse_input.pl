#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my $filename = shift;
$filename //= './kittens.in';
open(my $fh, '<', $filename);

my $first_line = <$fh>;

print $first_line;
