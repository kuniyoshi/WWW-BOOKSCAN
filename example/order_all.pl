#!/usr/bin/perl
use 5.10.0;
use utf8;
use strict;
use warnings;
use open qw( :utf8 :std );
use Config::Pit ( );
use Readonly;
use Time::Seconds qw( ONE_MINUTE );
use lib "../lib";
use WWW::BOOKSCAN;

Readonly my %INTERVAL => (
    order => 20 * ONE_MINUTE,
    prove => 5  * ONE_MINUTE,
);

my $config = Config::Pit::get( "bookscan.co.jp" );

my $bookscan = WWW::BOOKSCAN->new( %{ $config } );
$bookscan->login;

foreach my $order ( $bookscan->orders ) {
    say "order: $order";

    foreach my $pdf ( $order->pdfs ) {
        say "pdf: $pdf";

        while ( $bookscan->is_tuning ) {
            my $wait_minutes = $bookscan->get_tuning_wait_time // 0;
            sleep $wait_minutes * ONE_MINUTE + $INTERVAL{prove};
        }

        $pdf->optimize;

        sleep $INTERVAL{order};
    }
}

