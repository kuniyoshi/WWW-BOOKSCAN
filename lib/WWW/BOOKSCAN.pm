package WWW::BOOKSCAN;
use utf8;
use strict;
use warnings;
use base "Class::Accessor";
use Readonly;
use Carp qw( croak );
use Path::Class qw( file );
use Hash::MoreUtils qw( slice_exists );
use Web::Query;
use WWW::BOOKSCAN::UserAgent;
use WWW::BOOKSCAN::URL;
use WWW::BOOKSCAN::Order;
use WWW::BOOKSCAN::PDF;

our $VERSION = "0.03";

Readonly my @FIELDS => qw( username  password  ua  url );

__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    my $class = shift;
    my %param = @_;
    my $self  = bless \%param, $class;

    foreach my $name ( @FIELDS ) {
        my $method = "init_$name";

        next
            unless $self->can( $method );

        $self->$method( %param );
    }

    return $self;
}

sub init_ua {
    my $self  = shift;
    my %param = @_;

    $self->ua(
        WWW::BOOKSCAN::UserAgent->instance( slice_exists( \%param, qw( username password ) ) ),
    );

    return $self;
}

sub init_url {
    my $self = shift;

    $self->url( WWW::BOOKSCAN::URL->instance );

    return $self;
}

sub can_home_see {
    my $self = shift;
    my $title;

    my $res = $self->ua->get( $self->url->home );
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
        $self->url->login,
        {
            email    => $username,
            password => $password,
        },
    );

    return $self;
}

sub orders {
    my $self = shift;

    my $res    = $self->ua->get( $self->url->orders );
    my @orders = WWW::BOOKSCAN::Order->new_from_html( $res->decoded_content );

    return @orders;
}


sub optimized_pdfs {
    my $self = shift;

    my $res  = $self->ua->get( $self->url->optimized_pdfs );
    my @pdfs = WWW::BOOKSCAN::PDF->new_from_optimized_html( $res->decoded_content );

    return @pdfs;
}

sub is_tuning {
    my $self = shift;
    my $res  = $self->ua->get( $self->url->running_tuning );

    return -1 != index $res->decoded_content, "_check.pdf";
}

sub get_tuning_wait_time {
    my $self = shift;
    my $res  = $self->ua->get( $self->url->running_tuning );

    my( $minutes ) = $res->decoded_content =~ m{ 約 (\d+) 分 }msx;

    return $minutes;
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
      foreach my $pdf ( $order->pdfs ) {
          $pdf->save;
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
