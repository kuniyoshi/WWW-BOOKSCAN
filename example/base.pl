#!/usr/bin/perl
use 5.10.0;
use utf8;
use strict;
use warnings;
use open qw( :utf8 :std );
use Readonly;
use Config::Pit ( );
use File::Basename qw( basename );
use Data::Dumper;
use lib "../lib";
use WWW::BOOKSCAN;

my $basename = basename( $0, ".pl" );

my $config = Config::Pit::get( "bookscan.co.jp" );

$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 0;

my $bookscan = WWW::BOOKSCAN->new( %{ $config } );
$bookscan->login;

my $method = \&{ "main::$basename" };
$method->( );

exit;

sub base {
    die "This is base script, make symbolic links.";
}

sub list_orders {
    foreach my $order ( $bookscan->orders ) {
        say Dumper $order;
    }
}

sub list_pdfs {
    my @orders = @ARGV ? ( map { eval $_ } @ARGV ) : $bookscan->orders;

    foreach my $order ( @orders ) {
        foreach my $pdf ( $order->pdfs ) {
            say Dumper $pdf;
        }
    }
}

sub list_optimized_pdfs {
    foreach my $pdf ( $bookscan->optimized_pdfs ) {
        say Dumper $pdf;
    }
}

sub save_pdfs {
    while ( <> ) {
        my $pdf = eval $_;
        $pdf->save;
        printf "took: %.2f[s] of saving %s.\n", $pdf->took, $pdf;
    }
}

sub order_optimize {
    while ( <> ) {
        my $pdf = eval $_;
        $pdf->order;
    }
}

