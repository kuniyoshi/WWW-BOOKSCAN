package WWW::BOOKSCAN;
use utf8;
use strict;
use warnings;
use Readonly;
use Carp qw( croak );
use Class::Accessor "antlers";
use Path::Class qw( file );
use Hash::MoreUtils qw( slice_exists );
use LWP::UserAgent;
use Web::Query;
use HTTP::Cookies;
use WWW::BOOKSCAN::Order;
use WWW::BOOKSCAN::PDF;

our $VERSION = "0.01";

Readonly my $AGENT  => join "/", __PACKAGE__, $VERSION;
Readonly my %URL    => (
    login  => URI->new( "https://system.bookscan.co.jp/login.php" ),
    home   => URI->new( "https://system.bookscan.co.jp/mypage.php" ),
    orders => URI->new( "https://system.bookscan.co.jp/history.php" ),
);
Readonly my %COOKIE => (
    file     => "cookie.jar",
    autosave => 1,
);

has "username";
has "password";
has "cookie_jar";
has "ua";

sub new {
    my $class = shift;
    my %param = @_;
    my $self  = bless \%param, $class;

    $self->init_cookie_jar( slice_exists( \%param, "cookie_jar" ) );
    $self->init_ua;

    return $self;
}

sub init_cookie_jar {
    my $self       = shift;
    my $cookie_jar = { @_ }->{cookie_jar}
        // { slice_exists( \%COOKIE, qw( file autosave ) ) };

    if ( ref $cookie_jar eq ref { } ) {
        $self->cookie_jar( $cookie_jar );
    }
    elsif ( eval { $cookie_jar->isa( "HTTP::Cookies" ) } ) {
        $self->cookie_jar( $cookie_jar );
    }
    else {
        $self->cookie_jar( {
            file     => $cookie_jar,
            autosave => $COOKIE{autosave},
        } );
    }

    return $self;
}

sub init_ua {
    my $self = shift;

    $self->ua( LWP::UserAgent->new( agent => $AGENT ) );
    $self->ua->cookie_jar( $self->cookie_jar );

    return $self;
}

sub can_home_see {
    my $self = shift;
    my $title;

    my $res = $self->ua->get( $URL{home} );
    my $wq  = Web::Query->new_from_html( $res->decoded_content );
    $wq->find( "title" )->each( sub {
        $title = $_->text;
    } );

    return $title && -1 != index $title, "マイページ";
}

sub login {
    my $self = shift;
    my( $username, $password ) = @{ { @_ } }{ qw( username password ) };

    return $self
        if $self->can_home_see;

    $username //= $self->username;
    $password //= $self->password;

    croak "username required."
        unless $username;
    croak "password required."
        unless $password;

    my $res = $self->ua->post(
        $URL{login},
        {
            email    => $username,
            password => $password,
        },
    );

    return $self;
}

sub orders {
    my $self = shift;

    my $res    = $self->ua->get( $URL{orders} );
    my @orders = WWW::BOOKSCAN::Order->new_from_html( $res->decoded_content );

    return @orders;
}

sub pdfs_from {
    my $self  = shift;
    my $order = shift;

    my $res  = $self->ua->get( $order->url );
    my @pdfs = WWW::BOOKSCAN::PDF->new_from_html( $res->decoded_content );

    return @pdfs;
}

1;
__END__

=head1 NAME

WWW::BOOKSCAN - An interface to www.bookscan.co.jp

=head1 SYNOPSIS

  use WWW::BOOKSCAN;

  my $bookscan = WWW::BOOKSCAN->new;
  $bookscan->login(
      username => "foo",
      password => "bar",
  );

  foreach my $order ( $bookscan->orders ) {
      foreach my $pdf ( $bookscan->pdfs_from( $order ) ) {
          $pdf->save;

          $pdf->order_optimize( "iphone" );
      }
  }

=head1 DESCRIPTION

WWW::BOOKSCAN provides an interface to donwload PDFs.



=head1 AUTHOR

kuniyoshi kouji E<lt>kuniyoshi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
