package WWW::BOOKSCAN::PDF;
use utf8;
use strict;
use warnings;
use Readonly;
use Class::Accessor "antlers";
use URI;
use URI::QueryParam;
use List::MoreUtils qw( uniq );
use HTML::SimpleLinkExtor;

has "filename";

Readonly my %URL => (
    scheme => "https",
    host   => "system.bookscan.co.jp",
);

sub new { my $class = shift; bless { @_ }, $class }

sub new_from_html {
    my $class = shift;
    my $html  = shift;
    my @pdfs;

    my @hrefs = grep { $_->query_param( "f" ) || $_->query_param( "filename" ) }
                map  { URI->new( $_ ) }
                uniq
                do   {
                    my $extor = HTML::SimpleLinkExtor->new;
                    $extor->parse( $html );
                    $extor->href;
                };

    my %urls = (
        download => [ grep { $_->query_param( "f" ) }        @hrefs ],
        optimize => [ grep { $_->query_param( "filename" ) } @hrefs ],
    );

    @pdfs = map {
        my $pdf = $class->new( filename => $_->query_param( "f" ) );
        $pdf->url( download => $_ );
        $pdf;
    } @{ $urls{download} };

    foreach my $pdf ( @pdfs ) {
        my( $url ) = grep { $_->query_param( "filename" ) eq $pdf->filename }
                     @{ $urls{optimize} };

        $pdf->url( optimize => $url );
    }

    return @pdfs;
}

sub url {
    my $self = shift;
    my $for  = shift;

    return $self->{url}
        unless $for;

    return $self->{url}{ $for }
        unless @_;

    my $value = shift;

    return $self->{url}{ $for } = $value;
}

1;

