
=head1 NAME

NetSDS::Exceptions - NetSDS exceptions descriptors

=head1 SYNOPSIS

	use NetSDS::Exceptions;

	eval { dangerous_code(); };

	if (my $ex = NetSDS::Exception::File->caught()) {
		print "Oops! File error: " . $ex->message();
	}

	sub dangerous_code {
	...
	if (some_error_happened()) {
		NetSDS::Exception::File->throw( message => 'File is not readable!');
	}
	...
	}

=head1 DESCRIPTION

B<NetSDS::Exception> module 

=cut

package NetSDS::Exceptions;

use 5.8.0;
use strict;
use warnings;

use version; our $VERSION = version->declare('v3.0.0');

=head1 EXCEPTIONS

All NetSDS expections separated to few types to represent
more or less detailed information on problem happened.

=head2 Generic exceptions

these exceptions describes common types of errors that may happen in application.

=over

=item B<NetSDS::Exception::Generic> - generic exception

	NetSDS::Exception::Generic->throw( message => 'Some problem happened');

=item B<NetSDS::Exception::Type> - invalid type exception

	NetSDS::Exception::Type->throw( message => 'This should be integer value!');

=item B<NetSDS::Exception::Argument> - invalid argument list

	NetSDS::Exception::Argument->throw( message => 'method() called without mandatory parameter');

=item B<NetSDS::Exception::File> - file operation error

	NetSDS::Exception::File->throw( message => 'Cannot write file!');

=item B<NetSDS::Exception::Network> - network exception

	NetSDS::Exception::Network->throw( message => 'Cannot connect to remote hostname');

=back

=head2 DBMS specific exceptions

=over

=item B<NetSDS::Exception::DBI> - generic network exception

In addition to C<message> provides C<dberr> field with DBI specific message. 

	NetSDS::Exception::DBI->throw(
		message => 'Cannot connect to remote hostname',
		dberr => $dbh->errstr,
	);

=item B<NetSDS::Exception::DBI::Connect> - DBMS connection error

=item B<NetSDS::Exception::DBI::SQL> - SQL query error

=back

=head2 Application exceptions

=over

=item B<NetSDS::Exception::Conf> - configuration error

=item B<NetSDS::Exception::Logic> - critical business logic fault

=back

=cut

use Exception::Class (

	'NetSDS::Exception::Generic' => {
		'description' => 'Generic exception',
	},

	'NetSDS::Exception::Type' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'Invalid data type',
	},

	'NetSDS::Exception::Argument' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'Invalid arguments in function',
	},

	'NetSDS::Exception::File' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'File operation error',
	},

	'NetSDS::Exception::Network' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'Network operation error',
	},

	# DBMS related
	'NetSDS::Exception::DBI' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'General DBMS operation error',
		'fields'      => ['dberr'],
	},
	'NetSDS::Exception::DBI::Connect' => {
		'isa'         => 'NetSDS::Exception::DBI',
		'description' => 'DBMS connection error',
	},
	'NetSDS::Exception::DBI::SQL' => {
		'isa'         => 'NetSDS::Exception::DBI',
		'description' => 'SQL statement error',
	},

	# Application errors
	'NetSDS::Exception::Conf' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'Configuration file error',
	},

	'NetSDS::Exception::Logic' => {
		'isa'         => 'NetSDS::Exception::Generic',
		'description' => 'Critical business logic error',
	},

);

1;

__END__

=head1 EXAMPLES

=head1 BUGS

Unknown

=head1 SEE ALSO

L<Exception::Class>

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut

