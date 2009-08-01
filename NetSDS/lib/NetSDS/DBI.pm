#===============================================================================
#
#         FILE:  DBI.pm
#
#  DESCRIPTION:  DBI wrapper for NetSDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
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

use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = "1.200";

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

	my $this = $class->SUPER::new(
		dbh    => undef,
		dsn    => $params{dsn},
		user   => '',
		passwd => '',
		attrs  => {},
		sets   => [],
	);

	$this->mk_accessors('dbh');

	# Add initialization SQL queries
	$this->_add_sets( @{$sets} );

	$attrs->{PrintError} = 0;
	$this->_add_attrs( %{$attrs} );

	# Connect to DBMS
	$this->_connect();

	return $this;

} ## end sub new


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

	my ( $this, $sql, @params ) = @_;

	# First check connection and try to restore if necessary
	unless ( $this->_check_connection() ) {
		return $this->error("Database connection error!");
	}

	# Prepare cached SQL query
	my $sth = $this->dbh->prepare_cached($sql);
	unless ($sth) {
		return $this->error("Cant prepare SQL query: $sql");
	}

	# Execute SQL query
	$sth->execute(@params);

	return $sth;

} ## end sub call

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
	my ( $this, @sets ) = @_;

	push( @{ $this->{sets} }, @sets );

	return 1;
}

#***********************************************************************

=item B<_add_attrs()> - add DBI handler attributes

    $this->add_attrs(AutoCommit => 1);

=cut

#-----------------------------------------------------------------------
sub _add_attrs {
	my ( $this, %attrs ) = @_;

	%attrs = ( %{ $this->{attrs} }, %attrs );
	return %attrs;
}


#***********************************************************************

=item B<_check_connection()> - ping and reconnect

=cut 

#-----------------------------------------------------------------------

sub _check_connection {

	my ($this) = @_;

	if ( $this->dbh ) {
		if ( $this->dbh->ping() ) {
			return 1;
		} else {
			return $this->_connect();
		}
	}
}


#***********************************************************************

=item B<_connect()> - connect to DBMS

=cut 

#-----------------------------------------------------------------------

sub _connect {

	my ($this) = @_;

	# Try to connect to DBMS
	$this->dbh( DBI->connect_cached( $this->{dsn}, $this->{login}, $this->{passwd}, $this->{attrs} ) );

	if ( $this->dbh ) {

		# All OK - drop error state
		$this->error(undef);

		# Call startup SQL queries
		foreach my $row ( @{ $this->{sets} } ) {
			unless ( $this->dbh->do($row) ) {
				return $this->error( $this->dbh->errstr || 'Set error in connect' );
			}
		}

	} else {
		return $this->error( "Cant connect to DBMS: " . $DBI::errsts );
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


