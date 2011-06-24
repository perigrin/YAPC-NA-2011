#!/usr/bin/perl

use strict;
use PDF::API2;
use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;
use Text::CSV;
# use utf8;
use Encode;

my $main_counter;  # 6 people per page, double-sided
my ($front_page, $back_page);
my %offsets = (
   1 => [ 0.5/in, 8.5/in ],   # x and y offsets
   2 => [ 4.5/in, 8.5/in ],   # to positions 1-6 on each page
   3 => [ 0.5/in, 5.5/in ],
   4 => [ 4.5/in, 5.5/in ],
   5 => [ 0.5/in, 2.5/in ],
   6 => [ 4.5/in, 2.5/in ],
);
my %backside = (          # Where to put the backs so we can cut a single piece of paper
   1 => 2, 2 => 1, 3 => 4, 4 => 3, 5 => 6, 6 => 5,
);

my $pdf = PDF::API2->new();
my $photo_file = $pdf->image_png("Perl-onion.png");   # Loading this only once is more efficient

my $csv = Text::CSV->new({ binary => 1 });
open my $in, "<", "/tmp/export.csv" or die;   # http://www.yapc2011.us/yn2011/export
<$in>;   # header
while (my $row = $csv->getline($in)) {
   $main_counter++;
   unless ($main_counter <= 6 && $front_page) {
      $front_page = add_page();
      $back_page =  add_page();
      $main_counter = 1;
   }
   add_person($front_page, $main_counter,            $row);
   add_person($back_page,  $backside{$main_counter}, $row);
   # last if ($main_counter == 6);
}
$pdf->saveas('new.pdf');


sub add_person {
   my ($page, $position, $p) = @_;  # $p is a person -- a row from export.csv

   my ($x, $y) = @{$offsets{$position}};
 
   my $font = $pdf->corefont('Helvetica-Bold');
   my $text = $page->text();

   $text->font($font, 24);

   unless ($p->[7]) {    # pseudonymous
      $text->translate($x, $y);
      $text->text(decode('utf-8', $p->[4] . " " . $p->[5]));   # Jay Hannah
   }

   $text->translate($x, $y - 25);
   $text->fillcolor('#000066');
   $text->text(decode('utf-8', $p->[6]));                      # jhannah

   $font = $pdf->corefont('Helvetica');
   $text->font($font, 17);
   $text->fillcolor('#000000');
   $text->translate($x, $y - 45);
   $text->text(decode('utf-8', substr($p->[10], 0, 32)));      # Omaha.pm

   $text->translate($x, $y - 65);
   $text->text(decode('utf-8', $p->[17]));                     # Infinity Interactive

   $text->font($font, 17);
   $text->translate($x, $y - 160);
   $text->text(decode('utf-8', 'YAPC::NA::2011    Asheville, NC'));

}


sub add_page {
   my $page = $pdf->page();
   $page->mediabox('Letter');

   my $box = $page->gfx;
   $box->rect( 
      0.25/in, 0/in, 8/in, 9/in, 
   );
   $box->linewidth(1);
   $box->linedash(1,20);
   $box->stroke;
   my $line = $page->gfx;
   $line->move(0.25/in, 3/in);
   $line->line(8.25/in, 3/in);
   $line->stroke;
   $line->move(0.25/in, 6/in);
   $line->line(8.25/in, 6/in);
   $line->stroke;
   $line->move(0.25/in, 6/in);
   $line->line(8.25/in, 6/in);
   $line->stroke;
   $line->move(4.25/in, 0/in);
   $line->line(4.25/in, 9/in);
   $line->stroke;
   
   my $EGTransparent = $pdf->egstate();
   my $EGNormal = $pdf->egstate();
   $EGTransparent->transparency(0.9);
   $EGNormal->transparency(0);
   
   my $photo = $page->gfx;
   $photo->egstate($EGTransparent);
   $photo->image( $photo_file, 0.25/in, 0.5/in, 8/in, 8/in );
   $photo->egstate($EGNormal);

   return $page;
}


