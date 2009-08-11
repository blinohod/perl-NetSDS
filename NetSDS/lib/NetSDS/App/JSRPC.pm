#===============================================================================
#
#         FILE:  JSRPC.pm
#
#  DESCRIPTION:  NetSDS admin
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  10.08.2009 20:57:57 EEST
#===============================================================================

=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::App::JSRPC;

use 5.8.0;
use strict;
use warnings;

use JSON;
use base qw(NetSDS::App::FCGI);

use version; our $VERSION = "0.01";

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new();

	return $this;

}

#***********************************************************************

=item B<process()> - main JSON-RPC iteration

=cut

#-----------------------------------------------------------------------

sub process {

	my ($this) = @_;

	# TODO - implement request validation
	# Parse JSON-RPC2 request
	my $http_request = $this->param('POSTDATA');

	# Set response MIME type
	$this->mime('application/x-json-rpc');

	# Parse JSON-RPC call
	if ( my ( $js_method, $js_params, $js_id ) = $this->_request_parse($js_request) ) {

		# Try to call method
		if ( $this->can($js_method) ) {

			# Call method and hope it will give some response
			if ( my $result = $this->$js_method($js_params) ) {

				# Make positive response
				$this->data(
					$this->_make_result(
						result => $result,
						id     => $js_id
					)
				);

			} else {

				# Cant get positive result
				$this->data(
					$this->_make_error(
						code    => -32000,
						message => "Error response from method",
						id      => undef,
					)
				);
			}

		} else {

			# Cant find proper method
			$this->data(
				$this->_make_error(
					code    => -32601,
					message => "Cant find JSON-RPC method",
					id      => undef,
				)
			);
		}

	} else {

		# Send error object as a response
		$this->data(
			$this->_make_error(
				code    => -32700,
				message => "Cant parse JSON-RPC call",
				id      => undef,
			)
		);
	}

} ## end sub process

sub _make_result {

	my ( $this, %params ) = @_;

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

	* B<id> - the same as request Id (see specification)
	* B<code> - error code (default is -32603, internal error)
	* B<message> - error message

Returns JSON encoded error message

=cut 

#-----------------------------------------------------------------------

sub _make_error {

	my ( $this, %params ) = @_;

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


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


