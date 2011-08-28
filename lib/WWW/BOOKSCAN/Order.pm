package WWW::BOOKSCAN::Order;
use utf8;
use strict;
use warnings;
use Readonly;
use Class::Accessor "antlers";
use HTML::SimpleLinkExtor;
use URI;

has "url";

Readonly my %URL => (
    scheme => "https",
    host   => "system.bookscan.co.jp",
);

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

    @hrefs = map {
        my $url = URI->new( $_ );
        $url->scheme( $URL{scheme} );
        $url->host( $URL{host} );
        $url;
    } @hrefs;

    @orders = map { $class->new( url => $_ ) } @hrefs;

    return @orders;
}

1;

