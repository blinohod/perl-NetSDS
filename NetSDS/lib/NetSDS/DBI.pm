
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

use version; our $VERSION = version->declare('v3.0.0');

#===============================================================================

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

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

			# Set MySQL default init queries
			if ( 'mysql' eq $dsn_driver ) {
				unshift( @{$sets}, "SET NAMES utf8" );
			}

			# Set UTF-8 support
			$attrs = {
				%{$attrs},
				pg_enable_utf8    => 1,
				mysql_enable_utf8 => 1,
			};

		} else {
			NetSDS::Exception::DBI::Connect->throw( message => 'Cannot parse DSN.' );
		}

	} else {
		NetSDS::Exception::DBI::Connect->throw( message => 'Cannot connect without DSN provided.' );
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

	# Set module configuration parameters
	$self->{debug_sql}      = $params{debug_sql};         # SQL debugging flag
	$self->{prepare_cached} = $params{prepare_cached};    # Cache prepared statements by default

	# Create object accessor for DBMS handler
	$self->mk_accessors('dbh');

	# Add initialization SQL queries
	$self->_add_sets( @{$sets} );

	$attrs->{AutoCommit} = 1;                             # Commit each statement unless implicit transaction
	$attrs->{PrintError} = 0;                             # Errors output is implemented other way
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

	# Running SQL debug if required
	if ( $self->{debug_sql} ) {
		$self->log( "debug", "RUN SQL:\n$sql" );
	}

	$self->_check_connection();

	# Prepare SQL query
	my $sth = $self->{prepare_cached} ? $self->dbh->prepare_cached($sql) : $self->dbh->prepare($sql);

	unless ( defined $sth ) {
		NetSDS::Exception::DBI::SQL->throw( message => "Cannot prepare SQL query: $sql" );
	}

	# Execute SQL query
	my $rv = $sth->execute(@params);
	unless ( defined $rv ) {
		NetSDS::Exception::DBI::SQL->throw( message => "Cannot execute SQL query: $sql" );
	}

	return $sth;

} ## end sub call

#***********************************************************************

=item B<fetch_call($sql, @params)> - call and fetch result

Paramters: SQL query, parameters

Returns: arrayref of records as hashrefs

Example:

	# SQL DDL script:
	# create table users (
	# 	id serial,
	# 	login varchar(32),
	# 	passwd varchar(32)
	# );

	# Now we fetch all data to perl structure
	my $table_data = $db->fetch_call("select * from users");

	# Process this data
	foreach my $user (@{$table_data}) {
		print "User ID: " . $user->{id};
		print "Login: " . $user->{login};
	}

=cut 

#-----------------------------------------------------------------------

sub fetch_call {

	my ( $self, $sql, @params ) = @_;

	# Try to prepare and execute SQL statement
	if ( my $sth = $self->call( $sql, @params ) ) {
		# Fetch all data as arrayref of hashrefs
		return $sth->fetchall_arrayref( {} );
	} else {
		return $self->error("Can't execute SQL: $sql");
	}

}

#***********************************************************************

=item B<begin()> - start transaction

=cut

sub begin {

	my ($self) = @_;

	return $self->dbh->begin_work();
}

#***********************************************************************

=item B<commit()> - commit transaction

=cut

sub commit {

	my ($self) = @_;

	return $self->dbh->commit();
}

#***********************************************************************

=item B<rollback()> - rollback transaction

=cut

sub rollback {

	my ($self) = @_;

	return $self->dbh->rollback();
}

#***********************************************************************

=item B<quote()> - quote SQL string

Example:

	# Encode $str to use in queries
	my $str = "some crazy' string; with (dangerous characters";
	$str = $db->quote($str);

=cut

sub quote {

	my ( $self, $str ) = @_;

	return $self->dbh->quote($str);
}

#***********************************************************************

=back

=head1 INTERNAL METHODS 

=over

=item B<_add_sets()> - add initial SQL query

Example:

    $obj->_add_sets("set search_path to myscheme");
    $obj->_add_sets("set client_encoding to 'UTF-8'");

=cut

#-----------------------------------------------------------------------
sub _add_sets {
	my ( $self, @sets ) = @_;

	push( @{ $self->{sets} }, @sets );

	return 1;
}

#***********************************************************************

=item B<_add_attrs()> - add DBI handler attributes

    $self->_add_attrs(AutoCommit => 1);

=cut

#-----------------------------------------------------------------------
sub _add_attrs {
	my ( $self, %attrs ) = @_;

	%attrs = ( %{ $self->{attrs} }, %attrs );
	return %attrs;
}

#***********************************************************************

=item B<_check_connection()> - check connection to DBMS

Internal method checking connection and throw exception in case of problem.

=cut 

#-----------------------------------------------------------------------

sub _check_connection {

	my ($self) = @_;

	if ( $self->dbh ) {
		if ( $self->dbh->ping() ) {
			return 1;
		} else {
			NetSDS::Exception::DBI::Connect->throw( message => 'Lost connection to DBMS' );
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

	# Exit with exception if cannot process
	unless ( $self->dbh ) {
		NetSDS::Exception::DBI::Connect->throw( message => 'Cannot connect to DBMS: ' . $DBI::errstr );
	}

	# Call startup SQL queries
	foreach my $row ( @{ $self->{sets} } ) {

		# Disconnect if cannot launch setup queries
		unless ( $self->dbh->do($row) ) {
			$self->dbh->disconnect();
			NetSDS::Exception::DBI::Connect->throw( message => 'Cannot run setup SQL statement: ' . $self->dbh->errstr );
		}
	}

} ## end sub _connect

1;

__END__

=back

=head1 EXAMPLES

samples/testdb.pl

=head1 SEE ALSO

L<DBI>, L<DBD::Pg>

=head1 TODO

1. Make module less PostgreSQL specific.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2012 Net Style Ltd.

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

