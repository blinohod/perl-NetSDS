package NetSDS::Portal::App;
use strict;
use warnings;
use URI::Escape;
use Module::Load;
use base qw(NetSDS::App::GUI);

use constant authorize_map => {};

sub is_authorized {
	my ( $self, @acls ) = @_;
	foreach my $acl (@acls) {
		if ( !$self->user()->authorize($acl) ) {
			return 0;
		}
	}
	return 1;
}

sub new {
	my ( $class, %params ) = @_;
	my $self = $class->SUPER::new(%params);
	bless $self, $class;
	$self->mk_accessors(qw(module));
	$self->module( $params{module} );
	return $self;
}

sub initialize {
	my ( $self, %params ) = @_;
	$self->SUPER::initialize(%params);
	my $dbh = NetSDS::DBI->new(
		dsn    => $self->conf->{db}->{main}->{dsn},
		login  => $self->conf->{db}->{main}->{login},
		passwd => $self->conf->{db}->{main}->{passwd}
	) or die "Cannot start up without a DBMS. Please fix your configuration.";
	$self->dbh($dbh);
}

sub error_403 {
	my $self = shift;
	print $self->cgi()->header( -cookie => $self->cookie, -status => '403 Forbidden' );
	print "<html><head><title>NetSDS Portal &mdash; HTTP 403 Forbidden</title></head><body><h1>HTTP 403 &mdash; Forbidden</h1><p>If you see this page, the portal has no login URL configured. This " . "needs to be fixed.</p><p>Normally, you should not see this page.</p><p>Just for the record, the access rules to this page have just " . "made you not pass the face control.</p></body></html>";
}

sub dispatch_action {
	my ( $self, $action ) = @_;
	return $self->render_slave($self->module, $action, 'master', {});
} ## end sub dispatch_action

sub module_object {
	my ( $self, $module ) = @_;
	my $object;
	load $module;
	$object = $module->new( parent => $self );
	return $object;
}

sub render_slave {
	my ( $self, $module, $action, $aspect, $params ) = @_;
	my $object = $self->module_object($module);
	my ( $res_type, @params ) = $object->dispatch_result( $action, $aspect, $object->dispatch_action( $action, $aspect, $params ) );
	if ( $res_type eq 'page' ) {
		return ( $res_type, @params ) if wantarray;
		return $params[0]->{'content'};
	}
	return ( $res_type, @params );
}

sub dispatch_result_page {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	my $default_params = {
		appbar            => { module => 'NetSDS::Portal::Dashboard', action => 'default' },
		logged_in         => $self->user->is_authenticated,
		available_actions => $self->module_object( $self->module )->get_available_actions,
		userbar           => { module => 'NetSDS::Portal::Login',     action => 'userbar' }
	};
	my @params = ( %$default_params, %$res_data );
	my %hashpar = @params;
	foreach my $param ( keys %hashpar ) {
		if ( ref( $hashpar{$param} ) eq 'HASH' ) {
			$hashpar{$param} = $self->render_slave( $hashpar{$param}->{module}, $hashpar{$param}->{action}, ( defined( $hashpar{$param}->{aspect} ) ? $hashpar{$param}->{aspect} : 'slave' ), ( defined( $hashpar{$param}->{params} ) ? $hashpar{$param}->{params} : {} ) );
		}
	}
	print $self->cgi()->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
	print $self->{tmpl}->render( 'master', %hashpar );
}

1;
