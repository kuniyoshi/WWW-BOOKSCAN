package WWW::BOOKSCAN::URL;
use utf8;
use strict;
use warnings;
use base "Class::Singleton";
use Carp qw( carp );
use Readonly;
use URI;
use URI::QueryParam;

Readonly my %URL => (
    scheme         => "https",
    host           => "system.bookscan.co.jp",
    login          => URI->new( "https://system.bookscan.co.jp/login.php" ),
    home           => URI->new( "https://system.bookscan.co.jp/mypage.php" ),
    orders         => URI->new( "https://system.bookscan.co.jp/history.php" ),
    ordered_pdfs   => URI->new( "https://system.bookscan.co.jp/tunelablist.php" ),
    running_tuning => URI->new( "https://system.bookscan.co.jp/tunelabnowlist.php" ),
);
Readonly my @WISH_SCHEMES => qw( http  https );

sub new {
    my $class = shift;
    carp "Call instance instead.";
    return $class->instance( @_ );
}

sub _new_instance {
    my $class = shift;
    return bless { @_ }, $class;
}

sub url_for {
    my $self = shift;
    my $url  = URI->new( shift );

    unless ( $url->scheme ) {
        $url->scheme( $URL{scheme} );
    }

    return $url
        unless grep { $url->scheme eq $_ } @WISH_SCHEMES;

    unless ( eval { $url->host } ) {
        $url->host( $URL{host} );
    }

    return $url;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    ( my $method = $AUTOLOAD ) =~ s{ .* [:]{2} }{}msx;

    return $URL{ $method };
}

sub DESTROY { }

1;

