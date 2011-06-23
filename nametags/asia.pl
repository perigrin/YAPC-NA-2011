#!/usr/bin/perl

# I got this from miyagawa for YAPC::Asia Tokyo 2009
# https://gist.github.com/1042703 (lestrrat)

# This is how a YAPC is made.
# namecards are created by hand using this script.
# an SVG template is used as the base, and we insert user names
# and such with this script. weeeeee.
use strict;
use warnings;
use utf8;
use Encode;
use SVG;
use SVG::Parser;
use Text::CSV_XS;
use Locale::Country;
use LWP::UserAgent;

Locale::Country::rename_country('tw' => 'Taiwan');
Locale::Country::rename_country('kr' => 'Korea');

my $ua = LWP::UserAgent->new();
my $base_file = "namecard_2x5.svg";
my $payments_file = shift @ARGV || "sample.csv";
my $users_file    = shift @ARGV || "export";
my $out_dir = shift @ARGV || '.';
my $font = 'mplus-1c-medium';

my $csv = Text::CSV_XS->new({ binary => 1 });
sub read_csv {
    my ($csv, $csv_file, $verify_code) = @_;
    open my $fh, $csv_file or die $!;
    my $header = $csv->getline($fh);
    $csv->column_names(@$header);

    #my $font = '&quot;M+ 1c&quot;';

    my @data;
    while (!$csv->eof) {
        my $ref = $csv->getline_hr($fh);

        if ($verify_code->($ref)) {
            push @data, $ref;
        }
    }
    return @data;
}

my @payments = read_csv($csv, $payments_file, sub {
    my $ref = shift;
    return 0 unless $ref->{user_id};
    die if length $ref->{order_id} > 4;
    die if length $ref->{user_id} > 4;
    return 1;
} );
my %payments = map { ($_->{user_id} => $_) } @payments;

my @users = read_csv($csv, $users_file, sub {
    my $ref = shift;
    return 0 unless $ref->{user_id};
    return 1;
} );

while (my @chunk = splice(@users, 0, 10)) {
    my $first_id = $chunk[0]->{user_id};
    my $ox = 0;
    my $oy = 0;

    my $parser = SVG::Parser->new;
    my $svg = $parser->parse_file($base_file);

    for my $ref (@chunk) {
        my $name = get_name($ref);
        my $size = length($name) > 20 ? 18
                 : length($name) > 16 ? 21
                 : 24;

        $svg->text(x => $ox + 35, y => $oy + 55, style => { 'font-family' => $font, 'font-weight' => 'bold', 'color' => 'black', 'font-size' => $size }, 'font-family' => $font, 'font-size' => $size)->cdata($name);
        $svg->text(x => $ox + 35, y => $oy + 75, style => { 'font-family' => $font, 'color' => 'black', 'font-size' => 11 }, 'font-family' => $font, 'font-size' => 11)->cdata(($ref->{pm_group} ? "$ref->{pm_group} / " : "") . ($ref->{country} ? code2country($ref->{country}) : ''));
        if ($ref->{company}) {
            $svg->text(x => $ox + 35, y => $oy + 90, style => { 'font-family' => $font, color => 'red', 'font-size' => 11 }, 'font-family' => $font, 'font-size' => 11)->cdata( decode_utf8($ref->{company}) );
        }

        my $role = ($ref->{is_orga} || $ref->{is_staff}) ? 'STAFF' :
            $ref->{has_talk} ? 'SPEAKER' :'';

        if ($role) {
            $svg->text(x => $ox + 35, y => $oy + 25, style => { 'font-family' => $font, 'font-weight' => 'bold', 'color' => 'black', 'font-size' => 14 }, 'font-family' => $font, 'font-size' => 16)->cdata($role);
        }

        my $order_id = $payments{ $ref->{user_id} }->{order_id};
        my $user_id = $ref->{user_id};
        my $c = (3 * $user_id * $user_id - 2 * ($user_id % 9) + 7) % 10000;
        my $x = sprintf("%04d%04d%04d", $user_id, $order_id ? $order_id : '0000', $c);
        if (! $order_id) {
            $x .= "X";
        }

        $ua->mirror(
            "http://users.endeworks.jp/~daisuke/yapc2009/qrcode.cgi?v=1&m=2&token=$x",
            "$user_id-qr.png"
        );

        $svg->image(
            x => $ox + 30,
            y => $oy + 92,
            width => 59,
            height => 59,
            '-href' => "$user_id-qr.png",
            id => "$user_id-qrcode"
        );

        $svg->image(
            x => $ox + 115,
            y => $oy + 92,
            width => 160,
            height => 50,
            '-href' => "YAPCASIA_logo.svg",
            id => "$user_id-logo"
        );

        $svg->text(x => $ox + 226, y => $oy + 26, style => { 'font-family' => $font, color => 'black', 'font-size' => 8 }, 'font-family' => $font, 'font-size' => 8)->cdata(sprintf('%04d', $ref->{user_id}));

        $svg->text(x => $ox + 250, y => $oy + 26, style => { 'font-family' => $font, color => 'black', 'font-size' => 8 }, 'font-family' => $font, 'font-size' => 8)->cdata($order_id || '0000');


        $ox = $ox == 0 ? 296 : 0;
        $oy+= 168 if $ox == 0;
    }

    my $outfile = sprintf("%s/%04d.svg", $out_dir, $first_id);
    open my $out, ">:utf8", $outfile or die "$outfile: $!";
    print $out $svg->xmlify;
    warn $outfile, "\n";
}


sub get_name {
    my $ref = shift;

    if ($ref->{pseudonymous}) {
        return decode_utf8( $ref->{nick_name} );
    }

    if (is_cjk($ref)) {
        return decode_utf8( $ref->{last_name} . $ref->{first_name} );
    } else {
        return decode_utf8( join " ", $ref->{first_name}, $ref->{last_name} );
    }
}

sub is_cjk {
    my $ref = shift;
    my $name = decode_utf8($ref->{first_name} . $ref->{last_name});
    $name =~ /\p{Han}/;
}

