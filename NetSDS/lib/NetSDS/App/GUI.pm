package NetSDS::App::GUI;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::App';

use CGI::Fast;
use CGI::Cookie;

use NetSDS::AuthDB;

use NetSDS::Template;
use NetSDS::Util::String;

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

	$self->mk_accessors('cgi');             # CGI.pm object
	$self->mk_accessors('authdb');          # AAA data source (see NetSDS::AuthDB)
	$self->mk_accessors('auth_ok');         # Authentication status (0 - anonymous, 1 - authenticated)
	$self->mk_accessors('action');          # Action called
	$self->mk_accessors('cookie');          # cookies to set
	$self->mk_accessors('auth_uid');        # authenticated user ID
	$self->mk_accessors('auth_login');      # authenticated user login
	$self->mk_accessors('auth_session');    # session key (transfered in cookies)
	$self->mk_accessors('remote_ip');

	# Initialize common properties
	$self->cookie( [] );                    # HTTP cookes

	# Initialize template system
	$self->{template_dir} = $self->conf->{template_dir};
	$self->{tmpl} = NetSDS::Template->new( dir => $self->{template_dir} );

	# Initialize AAA component
	$self->authdb( NetSDS::AuthDB->new( %{ $self->conf->{db}->{main} } ) );
	if ( $self->authdb ) {
		$self->log( "info", "Successfully connected to AAA data source" );
	} else {
		$self->log( "error", "Cannot connect to AAA data source" );
		$self->{to_finalize} = 1;           # No sense to run without AuthDB
	}

} ## end sub initialize

sub main_loop {

	my ( $self, $method, $params ) = @_;

	$self->start();

	while ( my $cgi = CGI::Fast->new() ) {

		$self->cgi($cgi);    # initialize CGI.pm object

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
		my $action_method = "action_" . $self->action;
		unless ( $self->can($action_method) ) {
			$action_method = "action_unknown";
		}

		$self->authenticate();

		# Call action method and get result
		my ( $res_type, $res_data, $res_opts ) = $self->$action_method();

		if ( $res_type eq 'html' ) {
			print $cgi->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
			print $res_data;

		} elsif ( $res_type eq 'page' ) {
			print $cgi->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
			print $self->{tmpl}->render( $self->action, %$res_data );

		} elsif ( $res_type eq 'redirect' ) {
			print $cgi->header( -cookie => $self->cookie, -status => '302 Moved', 'Location' => $res_data );
		}

	} ## end while ( my $cgi = CGI::Fast...)

	$self->stop();

} ## end sub main_loop

sub action_unknown {

	my ($self) = @_;

	$self->log( "warning", "Unknown action called: " . $self->action() );

	return ( "html", "<h1>Unknown action call</h1>", undef );

}

sub action_default {

	my ($self) = @_;

	return ( "html", "<h1>Default action not defined</h1>", undef );

}

sub authenticate {

	my ($self) = @_;

	# Anonymous user by default
	$self->auth_ok(0);
	$self->auth_session(undef);
	$self->auth_uid(undef);
	$self->auth_login(undef);

	# Check if we have username and password HTTP request parameters
	if ( my $login = $self->cgi->param('u') and my $passwd = $self->cgi->param('p') ) {

		# Try password based authentication
		my ( $user_id, $new_sess ) = $self->authdb->auth_passwd( $login, $passwd, make_session => 1 );
		if ($user_id) {
			$self->log( "info", "UID: $user_id, SESS: $new_sess" );
			$self->auth_ok(1);
			$self->set_cookie( name => 'SESSID', value => $new_sess, expire => '+8h' );
			$self->auth_session($new_sess);
			$self->auth_uid($user_id);
			$self->auth_login( $self->authdb->get_user($user_id)->{login} );
		} else {
			$self->log( "warning", "Cannot authenticate by password: user='$login'; IP='" . $self->remote_ip() . "'" );
		}

	} else {

		# Try session based authentication
		my $sess_cookie = $self->get_cookie('SESSID');
		my ($sess_key) = $sess_cookie ? @{$sess_cookie} : undef;
		if ($sess_key) {
			$self->log( "info", "Try session based authentication: SESSID='$sess_key'" );
			if ( my $user_id = $self->authdb->auth_session( $sess_key, update => 1 ) ) {
				$self->log( "info", "Successfull authentication by session '$sess_key', uid=$user_id" );
				$self->auth_ok(1);
				$self->auth_session($sess_key);
				$self->auth_uid($user_id);
				$self->auth_login( $self->authdb->get_user($user_id)->{login} );
			} else {
				$self->log( "warning", "Cannot authenticate by session: SESSID='$sess_key'; IP='" . $self->remote_ip() . "'" );
			}

		} else {
			$self->log( "info", "Anonymous request: IP='" . $self->remote_ip() . "'" );
		}

	} ## end else [ if ( my $login = $self...)]

} ## end sub authenticate

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

