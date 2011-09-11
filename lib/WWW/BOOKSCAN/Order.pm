package WWW::BOOKSCAN::Order;
use utf8;
use strict;
use warnings;
use Class::Accessor "antlers";
use Readonly;
use HTML::SimpleLinkExtor;
use WWW::BOOKSCAN::URL;
use WWW::BOOKSCAN::UserAgent;

Readonly my @FIELDS => qw( resource );

has $_ foreach @FIELDS;

sub url { WWW::BOOKSCAN::URL->instance }

sub ua { WWW::BOOKSCAN::UserAgent->instance }

sub new { my $class = shift; bless { @_ }, $class }

sub new_from_html {
    my $class = shift;
    my $html  = shift;
    my @orders;

    my @hrefs = grep { -1 != index $_, "bookdetail.php" }
                do   {
                    my $extor = HTML::SimpleLinkExtor->new;
                    $extor->parse( $html );
                    $extor->href;
                };

    @orders = map { $class->new( resource => $class->url->url_for( $_ ) ) } @hrefs;

    return @orders;
}

sub pdfs {
    my $self = shift;

    my $res  = $self->ua->get( $self->resource );
    my @pdfs = WWW::BOOKSCAN::PDF->new_from_html( $res->decoded_content );

    return @pdfs;
}

use overload q{""} => \&as_string;

sub as_string { shift->resource }

1;

