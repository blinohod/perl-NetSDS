
=head1 NAME

NetSDS::Exceptions - NetSDS core exceptions

=head1 SYNOPSIS

	use NetSDS::Exceptions;

=head1 DESCRIPTION

B<NetSDS::Exception> module 

=cut

package NetSDS::Exceptions;

use 5.8.0;
use strict;
use warnings;

use version; our $VERSION = '2.000';

use Exception::Class (
	'NetSDS::Exception::Generic' => {
		'description' => 'Generic exception',
		'fields'      => ['message'],
	},
	'NetSDS::Exception::DBI' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'DBMS operation error',
	},
	'NetSDS::Exception::DBI::Connect' => {
		'isa'         => 'NetSDS::Exception::DBI',
		'description' => 'DBMS connection error',
	},
	'NetSDS::Exception::DBI::SQL' => {
		'isa'         => 'NetSDS::Exception::DBI',
		'description' => 'SQL statement error',
	},
);

1;

__END__

=back

=head1 EXAMPLES

=head1 BUGS

Unknown

=head1 SEE ALSO

L<Exception::Class>

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut

