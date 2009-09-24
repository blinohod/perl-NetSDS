#===============================================================================
#
#         FILE:  JSRPC.pm
#
#  DESCRIPTION:  NetSDS admin
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  10.08.2009 20:57:57 EEST
#===============================================================================

=head1 NAME

NetSDS::App::JSRPC - JSON-RPC server framework

=head1 SYNOPSIS

	use 5.8.0;

	JServer->run();

	1;

	package JServer;
	use base 'NetSDS::App::JSRPC';

	# This method is available via JSON-RPC
	sub sum {
		my ($self, $param) = @_;
		return $$param[0] + $$param[1];
	}

	1;

=head1 DESCRIPTION

C<NetSDS::App::JSRPC> module implements framework for common JSON-RPC service.

This implementation is based on L<NetSDS::App::FCGI> module and expected to be
executed as FastCGI or CGI service.

Both request and response should be of 'application/x-json-rpc' MIME type.

=cut

package NetSDS::App::JSRPC;

use 5.8.0;
use strict;
use warnings;

use JSON;
use base 'NetSDS::App::FCGI';


use version; our $VERSION = '1.205';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([...])> - class constructor

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	return $self;

}

#***********************************************************************

=item B<process()> - main JSON-RPC iteration

This is internal method that implements JSON-RPC call processing.

=cut

#-----------------------------------------------------------------------

sub process {

	my ($self) = @_;

	# TODO - implement request validation
	# Parse JSON-RPC2 request
	my $http_request = $self->param('POSTDATA');

	# Set response MIME type
	$self->mime('application/x-json-rpc');

	# Parse JSON-RPC call
	if ( my ( $js_method, $js_params, $js_id ) = $self->_request_parse($http_request) ) {

		# Try to call method
		if ( $self->can_method($js_method) ) {

			# Call method and hope it will give some response
			my $result = $self->process_call( $js_method, $js_params );
			if ( defined($result) ) {

				# Make positive response
				$self->data(
					$self->_make_result(
						result => $result,
						id     => $js_id
					)
				);

			} else {

				# Cant get positive result
				$self->data(
					$self->_make_error(
						code    => -32000,
						message => $self->errstr || "Error response from method $js_method",
						id      => undef,
					)
				);
			}

		} else {

			# Cant find proper method
			$self->data(
				$self->_make_error(
					code    => -32601,
					message => "Cant find JSON-RPC method",
					id      => undef,
				)
			);
		}

	} else {

		# Send error object as a response
		$self->data(
			$self->_make_error(
				code    => -32700,
				message => "Cant parse JSON-RPC call",
				id      => undef,
			)
		);
	}

} ## end sub process


#***********************************************************************

=item B<can_method($method_name)> - check method availability

Paramters: method name (string)

C<can_method()> 

=cut 

#-----------------------------------------------------------------------

sub can_method {
	my ($self, $method) = @_;
	return $self->can($method);
}

#***********************************************************************

=item B<process_call($method, $params)> - execute method call

Paramters: method name, parameters.

Returns parameters from executed method as is.

=cut 

#-----------------------------------------------------------------------

sub process_call {

	my ( $self, $method, $params ) = @_;

	return $self->$method($params);

}

#***********************************************************************

=item B<_request_parse($post_data)> - parse HTTP POST

Paramters: HTTP POST data as string

Returns: request method, parameters, id

=cut 

#-----------------------------------------------------------------------

sub _request_parse {

	my ( $self, $post_data ) = @_;

	my $js_request = eval { decode_json($post_data) };
	return $self->error("Cant parse JSON data") if $@;

	return ( $js_request->{'method'}, $js_request->{'params'}, $js_request->{'id'} );

}

#***********************************************************************

=item B<_make_result(%params)> - prepare positive response

Paramters:

=over

=item B<id> - the same as request Id (see specification)

=item B<result> - method result

=back

Returns JSON encoded response message

=cut 

#-----------------------------------------------------------------------

sub _make_result {

	my ( $self, %params ) = @_;

	# Prepare positive response

	return encode_json(
		{
			jsonrpc => '2.0',
			id      => $params{'id'},
			result  => $params{'result'},
		}
	);

}

#***********************************************************************

=item B<_make_error(%params)> - prepare error response

Internal method implementing error response.

Paramters:

=over

=item B<id> - the same as request Id (see specification)

=item B<code> - error code (default is -32603, internal error)

=item B<message> - error message

=back

Returns JSON encoded error message

=cut 

#-----------------------------------------------------------------------

sub _make_error {

	my ( $self, %params ) = @_;

	# Prepare error code and message
	# http://groups.google.com/group/json-rpc/web/json-rpc-1-2-proposal

	my $err_code = $params{code}    || -32603;              # 	Internal JSON-RPC error.
	my $err_msg  = $params{message} || "Internal error.";

	# Return JSON encoded error object
	return encode_json(
		{
			jsonrpc => '2.0',
			id      => $params{'id'},
			error   => {
				code    => $err_code,
				message => $err_msg,
			},
		}
	);

} ## end sub _make_error

1;

__END__

=back

=head1 EXAMPLES

See C<samples/app_jsrpc.fcgi> appliction.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<JSON>

L<JSON::RPC2>

=head1 TODO

* move error codes to constants

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


