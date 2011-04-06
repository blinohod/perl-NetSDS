package NetSDS::Portal::App;
use strict;
use warnings;
use URI::Escape;
use base qw(NetSDS::App::GUI NetSDS::App::I18NMixin);

__PACKAGE__->mk_class_accessors qw(authorize_map);
__PACKAGE__->authorize_map( {} );

sub is_authorized {
	my ( $self, @acls ) = shift;
	foreach my $acl (@acls) {
		return 0 if !$self->user()->authorize($acl);
	}
	return 1;
}

sub initialize {
	my ( $self, %params ) = @_;
	$self->SUPER::initialize(%params);
	$self->mk_accessors('dbh');
	my $dbh = NetSDS::DBI->new(
		dsn => $self->conf->{db}->{main}->{dsn},
		login => $self->conf->{db}->{main}->{login},
		passwd => $self->conf->{db}->{main}->{passwd}
	) or die "Cannot start up without a DBMS. Please fix your configuration.";
	$self->dbh($dbh);
}

sub error_403 {
	my $self = shift;
	print $self->cgi()->header( -cookie => $self->cookie, -status => '403 Forbidden' );
	print "<html><head><title>NetSDS Portal — HTTP 403 Forbidden</title></head><body><h1>HTTP 403 — Forbidden</h1><p>If you see this page, the portal has no login URL configured. This " . "needs to be fixed.</p><p>Normally, you should not see this page.</p><p>Just for the record, the access rules to this page have just " . "made you not pass the face control.</p></body></html>";
}

sub dispatch_action {
	my ( $self, $action ) = @_;
	my @acls =
	  ( __PACKAGE__->authorize_map()->{$action} )
	  ? @{ __PACKAGE__->authorize_map()->{$action} }
	  : ( ( __PACKAGE__->authorize_map()->{'*'} ) ? ( __PACKAGE__->authorize_map()->{"*"} ) : () );
	if ( scalar(@acls) ) {
		if ( $self->is_authorized(@acls) ) {
			return $self->SUPER::dispatch_action($action);
		} else {
			# Unauthorized access
			if ( $self->conf->{web}->{login_url} ) {
				my $url = sprintf( $self->conf->{web}->{login_url}, uri_escape( $self->cgi()->url( -absolute => 1 ) ) );
				return ( 'redirect', $url );
			} else {
				$self->error_403;
				return undef;
			}
		}
	} else {
		return $self->SUPER::dispatch_action($action);
	}
} ## end sub dispatch_action

sub dispatch_result_page {
	my ( $self, $action, $res_data, $res_opts ) = @_;
	my $default_params = {
		available_applications => $self->get_available_applications,
		logged_in              => $self->user->is_authenticated,
	};
	my @params = (%$default_params, %$res_data);
	print $self->cgi()->header( -type => 'text/html', -charset => 'utf-8', -cookie => $self->cookie );
	print $self->{tmpl}->render( $action, @params );
}

sub get_available_applications {
	my $self    = shift;
	my $rs      = $self->dbh->call('select uri as link, title_tag as title, descr from portal.applications order by priority asc');
	my $results = [];
	while ( my $row = $rs->fetchrow_hashref ) {
		push @$results, $row;
	}
	return $results;
}

1;
