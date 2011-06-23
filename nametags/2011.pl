use PDF::API2;
use constant mm => 25.4 / 72;
use constant in => 1 / 72;
use constant pt => 1;

$pdf = PDF::API2->new();
$page = $pdf->page();
$page = $pdf->openpage($page_number);
$page->mediabox('Letter');

$font = $pdf->corefont('Helvetica-Bold');
$text = $page->text();
$text->font($font, 20);
$text->translate(200, 700);
$text->text('Hello World!');

my $box = $page->gfx;
$box->rect( 
   0.25/in, 0.25/in, 8/in, 9/in, 
);
$box->linewidth(1);
$box->linedash(1,20);
$box->stroke;
my $line = $page->gfx;
$line->move(0.25/in, 3.25/in);
$line->line(8.25/in, 3.25/in);
$line->stroke;
$line->move(0.25/in, 6.25/in);
$line->line(8.25/in, 6.25/in);
$line->stroke;
$line->move(0.25/in, 6.25/in);
$line->line(8.25/in, 6.25/in);
$line->stroke;
$line->move(4.25/in, 0.25/in);
$line->line(4.25/in, 9.25/in);
$line->stroke;

my $EGTransparent = $pdf->egstate();
my $EGNormal = $pdf->egstate();
$EGTransparent->transparency(0.8);
$EGNormal->transparency(0);

my $photo = $page->gfx;
$photo->egstate($EGTransparent);
my $photo_file = $pdf->image_png("Perl-onion.png");
$photo->image( $photo_file, 0.25/in, 0.75/in, 8/in, 8/in );

$pdf->saveas('new.pdf');

