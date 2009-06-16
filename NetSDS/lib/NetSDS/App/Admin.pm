#===============================================================================
#
#         FILE:  Admin.pm
#
#  DESCRIPTION:  Administrative WWW framework
#
#        NOTES:  See Wiki page for details
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  15.07.2008 16:54:45 EEST
#===============================================================================

=head1 NAME

NetSDS::App::Admin - common webadmin framework

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::App::Admin;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::App::FCGI);

use NetSDS::Template;
use NetSDS::Report;
#use NetSDS::Auth;

use version; our $VERSION = "0.02";
our @EXPORT_OK = qw();

sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(
								  action		=> undef,
								  template_dir	=> undef,
								  tmpl			=> undef,
								  rpt			=> undef,
								  auth			=> undef,
								  service		=> undef,
								  group			=> undef,    # Group expected to use service
								  auth_ok		=> undef,
								  %params,
								 );

	return $this;

}

__PACKAGE__->mk_accessors(qw/template_dir tmpl rpt dbh auth service group auth_ok/);

#***********************************************************************

=head1 CLASS API

=over

=item B<initialize()> - application initialization

=cut 

#-----------------------------------------------------------------------

sub initialize {

	my ( $this, %params ) = @_;

	$this->SUPER::initialize(%params);

	# Initialize page templates
	$this->tmpl( NetSDS::Template->new( templates => $this->{conf}->{templates} ) );

	# Initialize report templates
	$this->rpt( NetSDS::Report->new( reports => $this->{conf}->{reports} ) ) if $this->{conf}->{reports};

	# Initialize DB driven APIs
	# $this->auth( NetSDS::Auth->new( %{ $this->{conf}->{db}->{main} } ) );
}

sub process {

	my ($this) = @_;

	# Search suitable action processor
	my $ac_sub = $this->action ? "ac_" . $this->action : "ac_default";

	# Set MIME type and charset
	$this->charset('utf-8');
	if ($ac_sub =~ /^ac_r(ep|pt)_/) {

		$this->mime('application/vnd.ms-excel');
		$this->headers(
					   {
						-expires				=> 'Mon, 26 Jul 1997 05:00:00 GMT',
						-cache_control			=> 'no-cache, must-revalidate',
						-content_disposition	=> 'attachment; filename=report.' . ($ac_sub =~ /^ac_rpt/ ? 'xls' : 'csv'),
						-content_description	=> 'NetSDS Generated Data',
					   }
					  );
	} else {

		$this->mime('text/html');
	}


	if ( $this->authenticate() and ($this->auth_ok)) {

		$this->log( 'info', "Action call: $ac_sub" );
		if ( $this->can($ac_sub) ) {
			$this->data( $this->$ac_sub );
		} else {
			$this->data( $this->ac_unknown() );
		}

		#} elsif ( $this->action("login") ) {

	} else {
		# Suggest login
		$this->data( $this->ac_default() );
	}

	my $menu = $this->tmpl->render('menu_unauth');
	if ( $this->auth_ok ) {
		$menu = $this->tmpl->render('menu_auth');
	}

	if ( $this->js_call() ) {
		$this->log( 'info', 'Call type: jQuery AJAX' );
	} elsif ( $this->raw_call() ) {
		$this->log( 'info', 'Call type: raw content' );
	} else {
		if ($ac_sub !~ /^ac_r(ep|pt)_/) {
			$this->data(
						$this->tmpl->render(
											'main',
											BODY   => $this->data,
											STATUS => $this->{status_message},
											MENU   => $menu,
										   )
					   );
		}
	}

} ## end sub process

#***********************************************************************

=item B<authenticate()> - authenticate user

This method provides user authentication

=cut 

#-----------------------------------------------------------------------

sub authenticate {
	my ($this) = @_;

	return 1;

}

#***********************************************************************

=item B<action()> - determine action called

This method determines requested action by C<a> request parameter.

=cut 

#-----------------------------------------------------------------------

sub action {
	my ($this) = @_;

	if ( my $act = $this->url_param('a') || $this->param('a') ) {

		if ( $act =~ /^[a-z_][a-z0-9_]{1,64}$/ ) {
			return $act;
		} else {
			return $this->error("Wrong action name: $act");
		}
	} else {

		return $this->error("No action requested");
	}

}

#***********************************************************************

=item B<ac_default()> - default action

This method provides default action. 

=cut 

#-----------------------------------------------------------------------

sub ac_default {
	my ($this) = @_;

	return "<p>Welcome to NetSDS VAS delivery suite!</p>";
}

#***********************************************************************

=item B<ac_unknown()> - unknown action

This method provides action if requested is not found. 

=cut 

#-----------------------------------------------------------------------

sub ac_unknown {
	my ($this) = @_;

	return "<p>Unknown action called!</p>";
}

sub raw_call {

	my ($this) = @_;

	if ( $this->param('m') and ( 'raw' eq $this->param('m') ) ) {
		return 1;
	} else {
		return undef;
	}

}

#***********************************************************************

=item B<js_call()> - determine if called with AJAX

Returns: true if AJAX call

This method determines AJAX call by C<X-Requested-With> header that shoud
have C<XmlHTTPRequest> value in this case.

=cut 

#-----------------------------------------------------------------------

sub js_call {

	my ($this) = @_;

	my $cond = ($this->http('HTTP_X_REQUESTED_WITH') && ($this->http('HTTP_X_REQUESTED_WITH') =~ /^XMLHttpRequest$/i)) ||
	  ($this->https('HTTP_X_REQUESTED_WITH') && ($this->http('HTTP_X_REQUESTED_WITH') =~ /^XmlHTTPRequest$/i));

	return $cond;

#	if ( $this->http('X-Requested-Width') and ( ( $this->http('X-Requested-Width') eq 'XmlHTTPRequest' ) or ( $this->https('X-Requested-Width') eq 'XmlHTTPRequest' ) ) ) {
#		return 1;
#	} else {
#		return undef;
#	}

}

sub make_sel_opts {

	my ( $this, @opts ) = @_;

	my $str = "";

	foreach (@opts) {
		$str .= "<option value='" . $_->{val} . "' ";
		if ( $_->{selected} ) { $str .= "selected='selected'"; }
		$str .= ">" . $_->{title} . "</option>\n";
	}

	return $str;

}
1;

__END__

=back

=head1 EXAMPLES

None yet

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


