package WWW::BOOKSCAN::UserAgent;
use utf8;
use strict;
use warnings;
use base "Class::Singleton";
use Carp qw( carp croak );
use Readonly;
use Path::Class qw( file );
use Hash::MoreUtils qw( slice_exists );
use LWP::UserAgent;

our $VERSION = "0.01";

Readonly my $AGENT  => join "/", __PACKAGE__, $VERSION;
Readonly my %COOKIE => (
    file     => "cookie.jar",
    autosave => 1,
);

sub new {
    my $class = shift;
    carp "Call instance instead.";
    return $class->instance( @_ );
}

sub _new_instance {
    my $class = shift;
    my %param = slice_exists( { @_ }, qw( username password cookie_jar ja ) );;
    my $self  = bless \%param, $class;

    $self->cookie_jar( $self->init_cookie_jar );
    $self->ua( $self->init_ua );

    return $self;
}

sub _accessor {
    my $self  = shift;
    my $field = shift;

    if ( @_ ) {
        $self->{ $field } = shift;
    }

    return $self->{ $field };
}

sub username { shift->_accessor( "username", @_ ) }

sub password { shift->_accessor( "password", @_ ) }

sub cookie_jar { shift->_accessor( "cookie_jar", @_ ) }

sub ua { shift->_accessor( "ua", @_ ) }

sub init_cookie_jar {
    my $self = shift;

    my $cookie_jar = { slice_exists( \%COOKIE, qw( file autosave ) ) };

    return $cookie_jar;
}

sub init_ua {
    my $self = shift;

    my $ua = LWP::UserAgent->new( agent => $AGENT );
    $ua->cookie_jar( $self->cookie_jar );

    return $ua;
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    ( my $method = $AUTOLOAD ) =~ s{ .* [:]{2} }{}msx;

    return $self->ua->$method( @_ )
        if $self->ua->can( $method );

    carp "Can't call $method from ua.";

    return $self;
}

sub DESTROY { }

1;

