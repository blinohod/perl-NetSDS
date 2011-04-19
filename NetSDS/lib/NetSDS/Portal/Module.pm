package NetSDS::Portal::Module;

use strict;
use warnings;
use version; our $VERSION = '1.000';
use mro 'c3';
use URI::Escape;
use base 'NetSDS::Class::Abstract';

sub new {
	my ( $class, %params ) = @_;
	my $self = $class->SUPER::new(%params);
	$self->mk_accessors qw(default_aspect parent);
	$self->default_aspect( $params{aspect} ? $params{aspect} : 'master' );
	$self->parent( $params{parent} );
	return $self;
}

sub cgi {
	my ($self) = @_;
	return $self->parent->cgi();
}

sub dbh {
	my ($self) = @_;
	return $self->parent->dbh();
}

sub user {
	my ($self) = @_;
	return $self->parent->user();
}

sub dispatch {
	my ( $self, $action, $aspect, $params ) = @_;
	my $action_method = "action_" . $action;
	unless ( $self->can($action_method) ) {
		$action_method = "action_unknown";
	}
	return $self->render( $action, $aspect, $self->$action_method( $aspect, $params ) );
}

sub _module {
	my ($self) = @_;
	my $result = ref($self);
	$result =~ s/::/./g;
	return lc($result);
}

sub dispatch_result {
	my ( $self, $action, $aspect, $res_type, $res_data, $res_opts ) = @_;
	if ( $self->can( 'dispatch_result_' . $res_type ) ) {
		my $method_name = 'dispatch_result_' . $res_type;
		return $self->$method_name( $action, $aspect, $res_data, $res_opts );
	}
	return ( $res_type, $res_data, $res_opts );
}

sub dispatch_action {
	my ( $self, $action, $aspect, $params ) = @_;
	my $acls =
	  ( $self->authorize_map()->{$action} )
	  ? $self->authorize_map()->{$action}
	  : ( ( $self->authorize_map()->{'*'} ) ? $self->authorize_map()->{"*"} : [] );
	if ( scalar(@$acls) ) {
		if ( $self->is_authorized(@$acls) ) {
			return $self->_do_dispatch_action( $action, $aspect, $params );
		} else {
			# Unauthorized access
			if ( $self->conf->{web}->{login_url} ) {
				my $url = sprintf( $self->conf->{web}->{login_url}, uri_escape( $self->cgi()->url( -absolute => 1 ) ) );
				return ( 'redirect', $url );
			} else {
				$self->error_403;
				return ( 'html', '' );
			}
		}
	} else {
		return $self->_do_dispatch_action( $action, $aspect, $params );
	}
} ## end sub dispatch_action

sub _do_dispatch_action {
	my ( $self, $action, $aspect, $params ) = @_;
	if ( $self->can( 'action_' . $action ) ) {
		my $action_method = 'action_' . $action;
		return $self->$action_method( $aspect, $params );
	}
	return $self->action_unknown( $aspect, $params );
}

sub dispatch_result_page {
	my ( $self, $action, $asp, $res_data, $res_opts ) = @_;
	my $module = $self->_module();
	my $result = '';
	foreach my $aspect ( $asp, 'master', '' ) {
		my $aspect_name = $aspect;
		$aspect_name = '.' . $aspect if $aspect ne '';
		my $template_name = "$module.$action$aspect_name";
		$result = $self->parent->{tmpl}->render( $template_name, %$res_data );
		next unless $result;
		last;
	}
	if ( $@ && ( $result eq '' ) && ( $self->SUPER::can('dispatch_result_page') ) ) {
		return $self->SUPER::dispatch_result_page( $action, $asp, $res_data, $res_opts );
	}
	return ( 'page', { 'content' => $result }, {} );
}

sub param {
	my ( $self, $params, $param_name ) = @_;
	if ( !$params->{$param_name} ) {
		return $self->cgi->param($param_name);
	}
	return $params->{$param_name};
}

sub is_authorized {
	my ( $self, @acls ) = @_;
	return $self->parent->is_authorized(@acls);
}

sub authdb {
	my ($self) = @_;
	return $self->parent->authdb();
}

sub set_cookie {
	my ( $self, @params ) = @_;
	return $self->parent->set_cookie(@params);
}

sub conf {
	my ($self) = @_;
	return $self->parent->conf();
}

sub action_unknown {
	my ( $self, $aspect, $params ) = @_;
	return ( 'page', {}, {} );
}

sub get_available_actions {
	my $self = shift;
	return undef;
}

1;
