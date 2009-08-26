#===============================================================================
#
#         FILE:  FCGI.pm
#
#  DESCRIPTION:  Common FastCGI applications framework
#
#        NOTES:  This fr
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  15.07.2008 16:54:45 EEST
#===============================================================================

=head1 NAME

NetSDS::App::FCGI - FastCGI applications superclass

=head1 SYNOPSIS

	# Run application
	MyFCGI->run();

	1;

	# Application package itself
	package MyFCGI;

	use base 'NetSDS::App::FCGI';

	sub process {
		my ($this) = @_;

		$this->data('Hello World');
		$this->mime('text/plain');
		$this->charset('utf-8');

	}


=head1 DESCRIPTION

C<NetSDS::App::FCGI> module contains superclass for FastCGI applications.
This class is based on C<NetSDS::App> module and inherits all its functionality
like logging, configuration processing, etc.

=cut

package NetSDS::App::FCGI;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::App';

use CGI::Fast;
use CGI::Cookie;


use version; our $VERSION = '1.202';


#***********************************************************************

=head1 CONSTRUCTOR

=over

=item B<new()> - constructor

Paramters: class parameters

Returns:

This method provides..... 

=cut 

#-----------------------------------------------------------------------

sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(
		cgi      => undef,
		mime     => undef,
		charset  => undef,
		data     => undef,
		redirect => undef,
		cookie   => undef,
		status   => undef,
		headers  => {},
		%params,
	);

	return $this;

}

#***********************************************************************

=back

=head1 CLASS AND OBJECT  METHODS

=over

=item B<cgi()> - accessor to CGI.pm request handler

	my $https_header = $this->cgi->https('X-Some-Header');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('cgi');

#***********************************************************************

=item B<status([$new_status])> - set response HTTP status

Paramters: new status to set

Returns: response status value

	$this->status('200 OK');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('status');

#***********************************************************************

=item B<mime()> - set response MIME type

Paramters: new MIME type for response

	$this->mime('text/xml'); # output will be XML data

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('mime');

#***********************************************************************

=item B<charset()> - set response character set if necessary

	$this->mime('text/plain');
	$this->charset('koi8-r'); # ouput as KOI8-R text

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('charset');

#***********************************************************************

=item B<data($new_data)> - set response data

Paramters: new data "as is"

	$this->mime('text/plain');
	$this->data('Hello world!');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('data');

#***********************************************************************

=item B<redirect($redirect_url)> - send HTTP redirect

Paramters: new URL (relative or absolute)

This method send reponse with 302 status and new location.

	if (havent_data()) {
		$this->redirect('http://www.google.com'); # to google!
	};

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('redirect');

#***********************************************************************

=item B<cookie()> - 

Paramters:

Returns:

This method provides..... 

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('cookie');

#***********************************************************************

=item B<headers($headers_hashref)> - set/get response HTTP headers

Paramters: new headers as hash reference

	$this->headers({
		'X-Beer' => 'Guiness',
	);

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('headers');

#***********************************************************************

=item B<main_loop()> - main FastCGI loop

Paramters: none

This method implements common FastCGI (or CGI) loop.

=cut 

#-----------------------------------------------------------------------

sub main_loop {

	my ($this) = @_;

	$this->start();

	$SIG{TERM} = undef;
	$SIG{INT}  = undef;

	# Enter FastCGI loop
	while ( $this->cgi( CGI::Fast->new() ) ) {

		# Retrieve request cookies
		$this->_set_req_cookies();

		# Set default response parameters
		$this->mime('text/plain');    # plain text output
		$this->charset('utf-8');      # UTF-8 charset
		$this->data('');              # empty string response
		$this->status("200 OK");      # everything OK
		$this->cookie( [] );          # no cookies
		$this->redirect(undef);       # no redirects

		# Call request processing method
		$this->process();

		# Send 302 and Location: header if redirect
		if ( $this->redirect ) {
			print $this->cgi->header(
				-cookie    => $this->cookie,
				-status    => '302 Moved',
				'Location' => $this->redirect
			);

		} else {

			# Implement generic content output
			use bytes;
			print $this->cgi->header(
				-type           => $this->mime,
				-status         => $this->status,
				-charset        => $this->charset,
				-cookie         => $this->cookie,
				-Content_length => bytes::length( $this->data ),
				%{ $this->headers },
			);
			no bytes;

			# Send return data to client
			if ( $this->data ) {
				binmode STDOUT;
				print $this->data;
			}
		} ## end else [ if ( $this->redirect )

	} ## end while ( $this->cgi( CGI::Fast...

	# Call finalization hooks
	$this->stop();

} ## end sub main_loop

#***********************************************************************

=item B<set_cookie(%params)> - set cookie

Paramters: hash (name, value, expires)

	$this->set_cookie(name => 'sessid', value => '343q5642653476', expires => '+1h');

=cut 

#-----------------------------------------------------------------------

sub set_cookie {

	my ( $this, %par ) = @_;

	push @{ $this->{cookie} }, $this->cgi->cookie( -name => $par{name}, -value => $par{value}, -expires => $par{expires} );

}

#***********************************************************************

=item B<get_cookie(%params)> - get cookie by name

Paramters: cookie name

Returns cookie value by it's name

	my $sess = $this->get_cookie('sessid');

=cut 

#-----------------------------------------------------------------------

sub get_cookie {

	my ( $this, $name ) = @_;

	return $this->{req_cookies}->{$name}->{value};

}

#***********************************************************************

=item B<param($name)> - CGI request parameter

Paramters: CGI parameter name

Returns: CGI parameter value

This method returns CGI parameter value by it's name.

	my $cost = $this->param('cost');

=cut 

#-----------------------------------------------------------------------

sub param {
	my ( $this, @par ) = @_;
	return $this->cgi->param(@par);
}

#***********************************************************************

=item B<url_param($name)> - CGI request parameter

Paramters: URL parameter name

Returns: URL parameter value

This method works similar to B<param()> method, but returns only parameters
from the query string.

	my $action = $this->url_param('a');

=cut

#-----------------------------------------------------------------------

sub url_param {
	my ( $this, @par ) = @_;
	return $this->cgi->url_param(@par);
}

#***********************************************************************

=item B<http($http_field)> - request HTTP header

Paramters: request header name

Returns: header value

This method returns HTTP request header value by name.

	my $beer = $this->http('X-Beer');

=cut 

#-----------------------------------------------------------------------

sub http {

	my $this = shift;
	my $par  = shift;

	return $this->cgi->http($par);
}

#***********************************************************************

=item B<https($https_field)> - request HTTPS header

This method returns HTTPS request header value by name and is almost
the same as http() method except of it works with SSL requests.

	my $beer = $this->https('X-Beer');

=cut 

#-----------------------------------------------------------------------

sub https {

	my $this = shift;
	my $par  = shift;

	return $this->cgi->https($par);
}

#***********************************************************************

=item B<raw_cookie()> - get raw cookie data

Just proxying C<raw_cookie()> method from CGI.pm

=cut 

#-----------------------------------------------------------------------

sub raw_cookie {
	my ($this) = @_;

	return $this->cgi->raw_cookie;
}

#**************************************************************************

=item B<user_agent()> - User-Agent request header

	my $ua_info = $this->user_agent();

=cut

#-----------------------------------------------------------------------
sub user_agent {
	my ($this) = @_;

	return $this->cgi->user_agent;
}

#***********************************************************************

=item B<request_method()> - HTTP request method

	if ($this->request_method eq 'POST') {
		$this->log("info", "Something POST'ed from client");
	}

=cut 

#-----------------------------------------------------------------------

sub request_method {
	my ($this) = @_;

	return $this->cgi->request_method;
}


#***********************************************************************

=item B<script_name()> - CGI script name

Returns: script name from CGI.pm

=cut 

#-----------------------------------------------------------------------

sub script_name {

	my ($this) = @_;

	return $this->cgi->script_name();
}

#***********************************************************************

=item B<path_info()> - get PATH_INFO value

	if ($this->path_info eq '/help') {
		$this->data('Help yourself');
	}

=cut 

#-----------------------------------------------------------------------

sub path_info {

	my ($this) = @_;

	return $this->cgi->path_info();
}

#***********************************************************************

=item B<remote_host()> - remote (client) host name

	warn "Client from: " . $this->remote_host();

=cut 

#-----------------------------------------------------------------------

sub remote_host {

	my ($this) = @_;

	return $this->cgi->remote_host();

}

#***********************************************************************

=item B<remote_addr()> - remote (client) IP address

Returns: IP address of client from REMOTE_ADDR environment

	if ($this->remote_addr eq '10.0.0.1') {
		$this->data('Welcome people from our gateway!');
	}

=cut 

#-----------------------------------------------------------------------

sub remote_addr {

	my ($this) = @_;

	return $ENV{REMOTE_ADDR};
}

#***********************************************************************

=item B<_set_req_cookies()> - fetching request cookies (internal method)

Fetching cookies from HTTP request to object C<req_cookies> variable.

=cut 

#-----------------------------------------------------------------------

sub _set_req_cookies {
	my ($this) = @_;

	my %cookies = CGI::Cookie->fetch();
	$this->{req_cookies} = \%cookies;

	return 1;
}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> catalog for more example code.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<CGI>, L<CGI::Fast>, L<NetSDS::App>

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


