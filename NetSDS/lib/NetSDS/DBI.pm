#===============================================================================
#
#         FILE:  DBI.pm
#
#  DESCRIPTION:  DBI wrapper for NetSDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  31.07.2009 13:56:33 UTC
#===============================================================================

=head1 NAME

NetSDS::DBI - DBI wrapper for NetSDS

=head1 SYNOPSIS

	use NetSDS::DBI;

	$dbh = NetSDS::DBI->new(
		dsn    => 'dbi:Pg:dbname=test;host=127.0.0.1;port=5432',
		login  => 'user',
		passwd => 'topsecret',
	);

	print $db->call("select md5(?)", 'zuka')->fetchrow_hashref->{md5};

=head1 DESCRIPTION

C<NetSDS::DBI> module provides wrapper around DBI module.

=cut

package NetSDS::DBI;

use 5.8.0;
use strict;
use warnings;

use DBI;

use base 'NetSDS::Class::Abstract';

use version; our $VERSION = '1.205';

#===============================================================================

=head1 CLASS METHODS

=over

=item B<new([...])> - constructor

    $dbh = NetSDS::DBI->new(
		dsn    => 'dbi:Pg:dbname=test;host=127.0.0.1;port=5432',
		login  => 'user',
		passwd => 'topsecret',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# DBI handler attributes
	my $attrs = { $params{attrs} ? %{ $params{attrs} } : () };

	# Startup SQL queries
	my $sets = $params{sets} || [];

	# Prepare additional parameters
	if ( $params{dsn} ) {

		# Parse DSN to determine DBD driver and provide
		my $dsn_scheme   = undef;
		my $dsn_driver   = undef;
		my $dsn_attr_str = undef;
		my $dsn_attrs    = undef;
		my $dsn_dsn      = undef;
		if ( ( $dsn_scheme, $dsn_driver, $dsn_attr_str, $dsn_attrs, $dsn_dsn ) = DBI->parse_dsn( $params{dsn} ) ) {

			# Set PostgreSQL default init queries
			if ( 'Pg' eq $dsn_driver ) {
				unshift( @{$sets}, "SET CLIENT_ENCODING TO 'UTF-8'" );
				unshift( @{$sets}, "SET DATESTYLE TO 'ISO'" );
			}

			# Set UTF-8 support
			$attrs = {
				%{$attrs},
				pg_enable_utf8 => 1,
			};

		} else {
			return $class->error( "Can't parse DBI DSN: " . $params{dsn} );
		}

	} else {
		return $class->error("Cant initialize DBI connection without DSN");
	}

	# initialize parent class
	my $self = $class->SUPER::new(
		dbh    => undef,
		dsn    => $params{dsn},
		login  => $params{login},
		passwd => $params{passwd},
		attrs  => {},
		sets   => [],
		%params,
	);

	# Implement SQL debugging
	if ($params{debug_sql}) {
		$self->{debug_sql} = 1;
	};

	# Create object accessor for DBMS handler
	$self->mk_accessors('dbh');

	# Add initialization SQL queries
	$self->_add_sets( @{$sets} );

	$attrs->{PrintError} = 0;
	$self->_add_attrs( %{$attrs} );

	# Connect to DBMS
	$self->_connect();

	return $self;

} ## end sub new

#***********************************************************************

=item B<dbh()> - DBI connection handler accessor

Returns: DBI object 

This method provides accessor to DBI object and for low level access
to database specific methods.

Example (access to specific method):

	my $quoted = $db->dbh->quote_identifier(undef, 'auth', 'services');
	# $quoted contains "auth"."services" now

=cut 

#-----------------------------------------------------------------------

#***********************************************************************

=item B<call($sql, @bind_params)> - prepare and execute SQL query

Method C<call()> implements the following functionality:

	* check connection to DBMS and restore it
	* prepare chached SQL statement
	* execute statement with bind parameters

Parameters:

	* SQL query with placeholders
	* bind parameters

Return:

	* statement handler from DBI 

Example:

	$sth = $dbh->call("select * from users");
	while (my $row = $sth->fetchrow_hashref()) {
		print $row->{username};
	}

=cut 

#-----------------------------------------------------------------------

sub call {

	my ( $self, $sql, @params ) = @_;

	# Debug SQL
	if ($self->{debug_sql}) {
		$self->log("debug", "SQL: $sql");
	};

	# First check connection and try to restore if necessary
	unless ( $self->_check_connection() ) {
		return $self->error("Database connection error!");
	}

	# Prepare cached SQL query
	# FIXME my $sth = $self->dbh->prepare_cached($sql);
	my $sth = $self->dbh->prepare($sql);
	unless ($sth) {
		return $self->error("Cant prepare SQL query: $sql");
	}

	# Execute SQL query
	$sth->execute(@params);

	return $sth;

} ## end sub call

#***********************************************************************

=item B<fetch_call($sql, @params)> - call and fetch result

Paramters: SQL query, parameters

Returns: arrayref of records as hashrefs

Example:

	my $table_data = $db->fetch_call("select * from users");

=cut 

#-----------------------------------------------------------------------

sub fetch_call {

	my ( $self, $sql, @params ) = @_;

	# Try to prepare and execute SQL statement
	if ( my $sth = $self->call( $sql, @params ) ) {
		# Fetch all data as arrayref of hashrefs
		return $sth->fetchall_arrayref( {} );
	} else {
		return $self->error("Cant execute SQL: $sql");
	}

}

#***********************************************************************

=back

=head1 INTERNAL METHODS 

=over

=item B<_add_sets()> - add initial SQL query

Example:

    $obj->add_sets("set search_path to myscheme");
    $obj->add_sets("set client_encoding to 'UTF-8'");

=cut

#-----------------------------------------------------------------------
sub _add_sets {
	my ( $self, @sets ) = @_;

	push( @{ $self->{sets} }, @sets );

	return 1;
}

#***********************************************************************

=item B<_add_attrs()> - add DBI handler attributes

    $self->add_attrs(AutoCommit => 1);

=cut

#-----------------------------------------------------------------------
sub _add_attrs {
	my ( $self, %attrs ) = @_;

	%attrs = ( %{ $self->{attrs} }, %attrs );
	return %attrs;
}

#***********************************************************************

=item B<_check_connection()> - ping and reconnect

Internal method checking connection and implement reconnect

=cut 

#-----------------------------------------------------------------------

sub _check_connection {

	my ($self) = @_;

	if ( $self->dbh ) {
		if ( $self->dbh->ping() ) {
			return 1;
		} else {
			return $self->_connect();
		}
	}
}

#***********************************************************************

=item B<_connect()> - connect to DBMS

Internal method starting connection to DBMS

=cut 

#-----------------------------------------------------------------------

sub _connect {

	my ($self) = @_;

	# Try to connect to DBMS
	$self->dbh( DBI->connect_cached( $self->{dsn}, $self->{login}, $self->{passwd}, $self->{attrs} ) );

	if ( $self->dbh ) {

		# All OK - drop error state
		$self->error(undef);

		# Call startup SQL queries
		foreach my $row ( @{ $self->{sets} } ) {
			unless ( $self->dbh->do($row) ) {
				return $self->error( $self->dbh->errstr || 'Set error in connect' );
			}
		}

	} else {
		return $self->error( "Cant connect to DBMS: " . $DBI::errsts );
	}

} ## end sub _connect

1;

__END__

=back

=head1 EXAMPLES

samples/testdb.pl

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


