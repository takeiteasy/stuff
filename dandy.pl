#!/usr/bin/env perl -w
use warnings;
use strict;

use feature qw(switch);
use open ':std', ':encoding(UTF-8)';

use LWP::Simple;
use HTML::TreeBuilder 5 -weak;

my $base_url = 'http://www.choi-waru.com/title/index_search.php?number=';

my $prog = '';
if ($prog eq '') {
    given ($^O) {
        when (/^(linux|freebsd|netbsd)$/i)  { $prog = "xdg-open" }
        when (/^(darwin|MacOS)$/i)          { $prog = "open" }
        when ("MSWin32")                    { $prog = "start" }
    }
    die "What OS are you even using? It's 2013, you know?" if $prog eq '';
}

my $tree = HTML::TreeBuilder->new;
foreach (@ARGV) {
    die "\"$_\" is not a number!" unless ($_ =~ /^(\d+)$/);
    my $content = get "$base_url$_" or die "ERROR! Failed to fetch URL!";
    $tree->parse($content);

    my $new_url = '';
    for my $link ($tree->look_down(_tag => 'a')) {
        my $href = $link->attr('href');
        $new_url = $href if $href =~ /^http:\/\/www\.choi-waru\.com\/title\/(\d+){4}\/(\d+){2}\/dandy_$_\.html$/;
        last unless $new_url eq '';
    }
    die "ERROR! DANDY-$_ not found!" if $new_url eq '';

    $content = get $new_url or die "ERROR! Failed to fetch URL!";
    $tree->parse($content);

    my @paragraphs = $tree->look_down(_tag => 'p');
    my $desc  = $paragraphs[1]->as_text();
    my @info  = split(' ', $paragraphs[2]->as_text());
    my @bolds = $tree->look_down(_tag => 'b');
    my $title = $bolds[$#bolds]->as_text();

    my @date_match  = $info[3] =~ m/(\d+)/g;
    my $date_month  = qw(January February  March  April  May  June July  August  September  October November December)[$date_match[0] - 1];
    my $day_suffix  = 'th';
       $day_suffix  = 'st' if $date_match[1] eq "1";
       $day_suffix  = 'nd' if $date_match[1] eq "2";

    print "TITLE:\n$title\n\nDESCRIPTION:\n$desc\n\nINFO:\n  $info[0]   / Director: $info[1]\n  $info[2] / Release:  $info[3] ($date_match[1]$day_suffix $date_month)\n  $info[4]   / Length:   $info[5] (minutes)\n  $info[6]   / Number:   $info[7]\n  $info[8]   / Price:    $info[9]\n";
    my $out = qx/$prog http:\/\/www.choi-waru.com\/title\/jacket_l\/dandy_$_.jpg/;

    print "\n\n" unless ($_ == $ARGV[$#ARGV]);
}
$tree->delete;

