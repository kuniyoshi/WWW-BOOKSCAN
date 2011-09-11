package WWW::BOOKSCAN::PDF;
use utf8;
use strict;
use warnings;
use Class::Accessor "antlers";
use Carp qw( carp croak );
use Readonly;
use List::Util qw( first );
use List::MoreUtils qw( uniq );
use HTML::SimpleLinkExtor;
use Web::Query;
use WWW::BOOKSCAN::URL;
use WWW::BOOKSCAN::UserAgent;

Readonly my @FIELDS  => qw( id  filename );
Readonly my %DEFAULT => (
    optimize_type => "iphone4",
    cover_flg     => 1,
);
Readonly my @TYPES   => qw(
    ipad  iphone4  kindle3  kindledx  android
    gtab  androidt2  sonyreader  nook  nookc
    biblio  jpg
);

has $_ foreach @FIELDS;

sub url { WWW::BOOKSCAN::URL->instance }

sub ua { WWW::BOOKSCAN::UserAgent->instance }

sub new { my $class = shift; bless { @_ }, $class }

sub resource {
    my $self = shift;
    my $for  = shift;

    return $self->{resource}
        unless $for;

    return $self->{resource}{ $for }
        unless @_;

    my $value = shift;

    return $self->{resource}{ $for } = $value;
}

sub new_from_html {
    my $class = shift;
    my $html  = shift;
    my @pdfs;

    my @hrefs = grep { $_->query_param( "f" ) || $_->query_param( "filename" ) }
                map  { $class->url->url_for( $_ ) }
                uniq
                do   {
                    my $extor = HTML::SimpleLinkExtor->new;
                    $extor->parse( $html );
                    $extor->href;
                };

    my %urls = (
        download => [ grep { $_->query_param( "f" )        } @hrefs ],
        optimize => [ grep { $_->query_param( "filename" ) } @hrefs ],
    );

    @{ $urls{download} } = map { $_->scheme( "http" ); $_ }
                           @{ $urls{download} };

    @pdfs = map {
        my $url = $_;
        my $pdf = $class->new(
            id       => scalar( $url->query_param( "f" ) ),
            filename => scalar( $url->query_param( "f" ) ),
        );
        $pdf->resource( download => $url );
        $pdf;
    } @{ $urls{download} };

    foreach my $pdf ( @pdfs ) {
        my( $url ) = grep { $_->query_param( "filename" ) eq $pdf->filename }
                     @{ $urls{optimize} };

        $pdf->resource( optimize => $url );
    }

    return @pdfs;
}

sub new_from_ordered_html {
    my $class = shift;
    my $html  = shift;
    my @pdfs;

    my @urls = grep { $_->query_param( "optimize" ) }
               map  { $class->url->url_for( $_ ) }
               uniq
               do   {
                   my $extor = HTML::SimpleLinkExtor->new;
                   $extor->parse( $html );
                   $extor->href;
               };

    foreach my $url ( @urls ) {
        my $filename = $url->query_param( "f" );
        my $id       = do {
            my @partial = split q{_}, $filename;
            shift @partial;
            join q{_}, @partial;
        };

        my $pdf = $class->new(
            id       => $id,
            filename => $filename,
        );
        $pdf->resource( download => $url );

        push @pdfs, $pdf;
    }

    return @pdfs;
}

use overload q{""} => \&as_string;

sub as_string { shift->resource( "download" ) }

sub save {
    my $self = shift;
    my( $overwrite, $as ) = @{ { @_ } }{ qw( overwrite as ) };
    my $filename = $as // $self->filename;

    if ( -e $filename ) {
        if ( defined $overwrite && ! $overwrite ) {
            return;
        }
        elsif ( ! defined $overwrite ) {
            carp "$filename already exists, if ignore this, add 'overwrite' option.";
            return;
        }
    }

    $self->ua->get(
        $self->resource( "download" ),
        ":content_file" => $filename,
    );

    return $filename;
}

sub optimize {
    my $self = shift;
    my( $for, $add_cover ) = @{ { @_ } }{ qw( for add_cover ) };
    my %param;

    croak "No optimize URL found."
        unless $self->resource( "optimize" );

    $param{optimize_type} = do {
        my $candidate = $for // $DEFAULT{optimize_type};
        first { $_ eq $candidate } @TYPES;
    };
    $param{cover_flg} = $add_cover // $DEFAULT{cover_flg};

    my $res = $self->ua->get( $self->resource( "optimize" ) );
    my $wq  = Web::Query->new_from_html( $res->decoded_content );

    $wq->find( "input" )->each( sub {
        my $input = $_;

        return
            if ! $input->attr( "type" ) || $input->attr( "type" ) ne "hidden";

        $param{ $input->attr( "name" ) } = $input->attr( "value" );
    } );

    $res = $self->ua->post(
        $self->resource( "optimize" ),
        \%param,
    );

    return $self;
}

1;

