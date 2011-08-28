#!/usr/bin/perl
use 5.10.0;
use utf8;
use strict;
use warnings;
use open qw( :utf8 :std );
use lib "lib";
use WWW::BOOKSCAN;
use Config::Pit ( );
use Data::Dumper qw( Dumper );
use Data::Printer;

my $config = Config::Pit::get( "bookscan.co.jp" );

my $bookscan = WWW::BOOKSCAN->new( %{ $config } );
$bookscan->login;

foreach my $order ( $bookscan->orders ) {
    p $order;

    foreach my $pdf ( $bookscan->pdfs_from( $order ) ) {
        p $pdf;
    }
}

