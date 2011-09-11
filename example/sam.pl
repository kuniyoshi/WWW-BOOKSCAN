#!/usr/bin/perl -s
use 5.10.0;
use utf8;
use strict;
use warnings;
use open qw( :utf8 :std );
use Readonly;
use Time::Seconds qw( ONE_MINUTE );
use Config::Pit ( );
use lib "../lib";
use WWW::BOOKSCAN;

our $save_raw, $optimize, $save_optimized;

Readonly my $INTERVAL => 20 * ONE_MINUTE;
Readonly my $LIMIT    => 3;

die usage( )
    unless grep { $_ } $save_raw, $optimize, $save_optimized;

my $config = Config::Pit::get( "bookscan.co.jp" );

my $bookscan = WWW::BOOKSCAN->new( %{ $config } );
$bookscan->login;

save_raw( )
    if $save_raw;

optimize( )
    if $optimize;

save_optimized( )
    if $save_optimized;

exit;

sub save_raw {
    foreach my $order ( $bookscan->orders ) {
        say $order;

        foreach my $pdf ( $order->pdfs ) {
            say $pdf;
            $pdf->save;
        }
    }
}

sub optimize {
    foreach my $order ( $bookscan->orders ) {
        say $order;

        foreach my $pdf ( $orders->pdfs ) {
            my $count;
            say $pdf;

            while ( $bookscan->is_tuning ) {
                die "Somethig went bad."
                    if ++$count > $LIMIT;

                sleep $INTERVAL;
            }

            $pdf->optimize;
        }
    }
}

sub save_optimized {
    foreach my $pdf ( $bookscan->optimized_pdfs ) {
        say $pdf;
        $pdf->save;
    }
}

exit;

sub usage {
    return <<USAGE;
usage: $0 <run mode>
  run mode:
    -save_raw
    -optimize
    -save_optimized
USAGE
}

