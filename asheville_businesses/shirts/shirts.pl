#!/usr/bin/perl

use strict;
use 5.10.0;
use Text::CSV;
use POSIX qw(ceil);

my (%counts, $total);
my $csv = Text::CSV->new({ binary => 1 });
open my $in, "<", "/tmp/export.csv" or die;   # http://www.yapc2011.us/yn2011/export
<$in>;   # header
while (my $row = $csv->getline($in)) {
   next unless ($row->[14]);
   $counts{$row->[14]}++;
   $total++;
}

my $target = 350;
my $multiplier = $target / $total;
printf(
   "%s sizes are declared. The target is %s, so we're multiplying by %0.1f and then rounding up.\n",
   $total, $target, $multiplier,
);

my $newtotal;
foreach my $size (sort keys %counts) {
   my $qty = ceil($counts{$size} * $multiplier);
   $newtotal += $qty;
   printf("%3s %s\n", $qty, $size);

}
say "Total: $newtotal";


