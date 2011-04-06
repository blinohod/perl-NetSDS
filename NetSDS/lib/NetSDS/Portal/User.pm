package NetSDS::Portal::User;
use 5.8.0;
use strict;
use warnings;
use base 'NetSDS::Class::Abstract';

sub new {
	my $self = {};
	my ( $class, $backend, $service ) = @_;
	bless $self, $class;
	$self->mk_accessors(qw(backend is_authenticated session_key uid service));
	$self->backend($backend);
	$self->is_authenticated(0);
	$self->service($service);
	return $self;
}

sub authenticate {
	my ( $self, %params ) = @_;
	$self->is_authenticated(0);
	$self->session_key(undef);
	$self->uid(undef);
	$self->username(undef);
	if ( my $login = $params{'username'} and my $passwd = $params{'password'} ) {
		# Try password based authentication
		my ( $user_id, $new_sess ) = $self->backend->auth_passwd( $login, $passwd, make_session => 1 );
		if ($user_id) {
			$self->log( "info", "UID: $user_id, SESS: $new_sess" );
			$self->is_authenticated(1);
			$self->session_key($new_sess);
			$self->uid($user_id);
			$self->username( $self->backend->get_user($user_id)->{login} );
		} else {
			$self->log( "warning", "Cannot authenticate by password: user='$login'; IP='" . $self->remote_ip() . "'" );
		}
	} else {
		# Try session based authentication
		my $sess_cookie = $params{'session_key'};
		my ($sess_key) = $sess_cookie ? @{$sess_cookie} : undef;
		if ($sess_key) {
			$self->log( "info", "Try session based authentication: SESSID='$sess_key'" );
			if ( my $user_id = $self->authdb->auth_session( $sess_key, update => 1 ) ) {
				$self->log( "info", "Successfull authentication by session '$sess_key', uid=$user_id" );
				$self->is_authenticated(1);
				$self->session_key($sess_key);
				$self->uid($user_id);
				$self->username( $self->backend->get_user($user_id)->{login} );
			} else {
				$self->log( "warning", "Cannot authenticate by session: SESSID='$sess_key'; IP='" . $self->remote_ip() . "'" );
			}
		} else {
			$self->log( "info", "Anonymous request: IP='" . $self->remote_ip() . "'" );
		}
	}
} ## end sub authenticate

sub authorize {
	my ($self, $action) = @_;
	my @result = $self->backend()->authorize($self->uid(), $self->service(), $action);
	return $result[0];
}

1;
