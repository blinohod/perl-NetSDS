package NetSDS::App::GUI;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::App';

use CGI::Cookie;
use CGI::Fast;
use JSON;

use NetSDS::AuthDB;

use NetSDS::Template;
use NetSDS::Util::String;
use NetSDS::Portal::User;

#===============================================================================

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

    my $object = NetSDS::App::GUI->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(
		daemon      => 0,
		use_pidfile => 0,
		%params
	);

	return $self;

}

sub initialize {

	my ( $self, %params ) = @_;

	# Initialize common NetSDS application
	$self->SUPER::initialize(%params);

	# Initialize accessors to resources and request parameters

	$self->mk_accessors('cgi');       # CGI.pm object
	$self->mk_accessors('authdb');    # AAA data source (see NetSDS::AuthDB)
	$self->mk_accessors('user');      # User object (see NetSDS::Portal::User)
	$self->mk_accessors('action');    # Action called
	$self->mk_accessors('cookie');    # cookies to set
	$self->mk_accessors('remote_ip');
	$self->mk_accessors('dbh'); # Main DB handle to use

	# Initialize common properties
	$self->cookie( [] );              # HTTP cookes

	# Initialize template system
	$self->{template_dir} = $self->conf->{template_dir};

	$self->{tmpl} = NetSDS::Template->new( dir => $self->{template_dir} );
	# Initialize AAA component
	$self->authdb( NetSDS::AuthDB->new( %{ $self->conf->{db}->{main} } ) );
	if ( $self->authdb ) {
		$self->log( "info", "Successfully connected to AAA data source" );
	} else {
		$self->log( "error", "Cannot connect to AAA data source" );
		$self->{to_finalize} = 1;     # No sense to run without AuthDB
	}

} ## end sub initialize

sub main_loop {
	$CGI::Fast::Ext_Request = FCGI::Request( \*STDIN, \*STDOUT, \*STDERR, \%ENV, 0, FCGI::FAIL_ACCEPT_ON_INTR());
	my ( $self, $method, $params ) = @_;
	$self->start();
	while ( !$self->{to_finalize} && (my $cgi = CGI::Fast->new()) ) {

		$self->cgi($cgi);
		$self->remote_ip( $self->cgi->remote_addr() );

		# Retrieve request cookies
		$self->_set_req_cookies();

		$self->action(undef);
		my $path = $cgi->path_info();

		# Determine action by PATH_INFO
		if ( $path =~ /\/(\w[a-zA-Z0-9\_]+)/ ) {
			$self->action( lc($1) );
		} else {
			$self->action('default');
		}

		# Find action handling method

		$self->authenticate(session_key => $self->cgi->cookie('SESSID'));

		# Call action method and get result
		my ( $res_type, $res_data, $res_opts ) = $self->dispatch_action($self->action);
		$self->dispatch_result( $self->action, $res_type, $res_data, $res_opts );

	} ## end while ( my $cgi = CGI::Fast...)

	$self->stop();

} ## end sub main_loop

sub dispatch_action {
	my ( $self, $action ) = @_;
	$self->action($action);
	my $action_method = "action_" . $action;
	unless ( $self->can($action_method) ) {
		$action_method = "action_unknown";
	}
	return $self->$action_method();
}

sub dispatch_result {
	my ( $self, $action, $res_type, $res_data, $res_opts ) = @_;
	if ( my $method = $self->can( 'dispatch_result_' . $res_type ) ) {
		$self->$method( $action, $res_data, $res_opts );
	} else {
		$self->log( "info", "Cannot dispatch result type $res_type" );
	}
}

sub dispatch_result_html {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	print $self->cgi()->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
	print $res_data;
}

sub dispatch_result_page {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	print $self->cgi()->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
	print $self->{tmpl}->render( $action, %$res_data );
}

sub dispatch_result_redirect {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	print $self->cgi()->header( -cookie => $self->cookie, -status => '302 Moved', 'Location' => $res_data );
}

sub dispatch_result_json {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	print $self->cgi()->header( -type => 'text/json', -charset => 'utf-8', -cookie => $self->cookie );
	print JSON::encode($res_data);
}

sub action_unknown {

	my ($self) = @_;

	$self->log( "warning", "Unknown action called: " . $self->action() );

	return ( "html", "<h1>Unknown action call</h1>", undef );

}

sub action_default {

	my ($self) = @_;

	return ( "html", "<h1>Default action not defined</h1>", undef );

}

sub forward {
	my ($self, $action) = @_;
	return $self->dispatch_action($action);
}

sub authenticate {
	my ($self)      = @_;
	my $sess_cookie = $self->get_cookie('SESSID');
	my ($sess_key)  = $sess_cookie ? @{$sess_cookie} : undef;
	$self->user(NetSDS::Portal::User->new($self->authdb, '', parent => $self));
	if ($sess_key) {
		$self->user()->authenticate( session_key => $sess_key );
	}
}

sub set_cookie {

	my ( $self, %par ) = @_;

	push @{ $self->{cookie} }, $self->cgi->cookie( -name => $par{name}, -value => $par{value}, -expires => $par{expires} );

}

sub get_cookie {

	my ( $self, $name ) = @_;

	return $self->{req_cookies}->{$name}->{value};

}

sub _set_req_cookies {

	my ($self) = @_;

	my %cookies = CGI::Cookie->fetch();
	$self->{req_cookies} = \%cookies;

	return 1;
}

sub start { }
sub stop  { }

1;

