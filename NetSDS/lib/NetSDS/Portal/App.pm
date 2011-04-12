package NetSDS::Portal::App;
use strict;
use warnings;
use URI::Escape;
use base qw(NetSDS::App::GUI);

use constant authorize_map => {};

sub is_authorized {
	my ( $self, @acls ) = @_;
	foreach my $acl (@acls) {
		print STDERR "$acl\n";
		if ( !$self->user()->authorize($acl) ) {
			return 0;
		}
	}
	return 1;
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
	$self->authorize_map({});
}

sub error_403 {
	my $self = shift;
	print $self->cgi()->header( -cookie => $self->cookie, -status => '403 Forbidden' );
	print "<html><head><title>NetSDS Portal &mdash; HTTP 403 Forbidden</title></head><body><h1>HTTP 403 &mdash; Forbidden</h1><p>If you see this page, the portal has no login URL configured. This " . "needs to be fixed.</p><p>Normally, you should not see this page.</p><p>Just for the record, the access rules to this page have just " . "made you not pass the face control.</p></body></html>";
}

sub dispatch_action {
	my ( $self, $action ) = @_;
	my $acls =
	  ( $self->authorize_map()->{$action} )
	  ? $self->authorize_map()->{$action}
	  : ( ( $self->authorize_map()->{'*'} ) ? $self->authorize_map()->{"*"} : [] );
	print STDERR sprintf("Authorizing via [%s]\n", join(', ', @$acls));
	print STDERR sprintf("Current UID: [%s]\n", $self->user->uid);
	if ( scalar(@$acls) ) {
		if ( $self->is_authorized(@$acls) ) {
			return $self->SUPER::dispatch_action($action);
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
		return $self->SUPER::dispatch_action($action);
	}
} ## end sub dispatch_action

sub get_available_actions {
	my $self = shift;
	return undef;
}

sub dispatch_result_page {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	my $default_params = {
		available_applications => $self->get_available_applications,
		logged_in              => $self->user->is_authenticated,
		username               => $self->user->username,
		available_actions      => $self->get_available_actions,
		logout_url             => $self->conf->{web}->{logout_url}
	};
	my @params = ( %$default_params, %$res_data );
	print $self->cgi()->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
	print $self->{tmpl}->render( $self->name() . "." . $action, @params );
}

sub get_available_applications {
	my $self = shift;
	my $rs   = $self->dbh->call(
		'select a.uri as link, a.title_tag as title, a.descr from portal.applications a 
		where auth.authorize(?, a.name, \'access\') order by a.priority asc', $self->user->uid()
	);
	my $results = [];
	while ( my $row = $rs->fetchrow_hashref ) {
		if ( $row->{link} eq $self->cgi->script_name ) {
			$row->{current} = 1;
		}
		push @$results, $row;
	}
	return $results;
}

1;
