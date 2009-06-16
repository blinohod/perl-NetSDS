#===============================================================================
#
#         FILE:  DB.pm
#
#  DESCRIPTION:  Common DBMS routines
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  07.05.2008 10:52:40 EEST
#===============================================================================

=head1 NAME

NetSDS::DB - most common DBMS wrapper for NetSDS

=head1 SYNOPSIS

	use NetSDS::DB;

	my $db = NetSDS::DB->new(
		dsn => 'dbi:Pg:dbname=nibelite;host=192.168.1.2',
		user => 'dbuser',
		passwd => 'topsecret',
		sets => [
			"insert into history (msg) values ('connected')",
		],
		preps => {
			'select_message' => 'select * from messages where status =0 limit 1',
		}
	);

=head1 DESCRIPTION

This module provides common database handling routines.

=cut

package NetSDS::DB;

use 5.8.0;
use strict;
use warnings;

use DBI;
use base qw(NetSDS::Class::Abstract);

use NetSDS::Util::Struct qw(
  merge_hash
  dump2row
);

use version; our $VERSION = "0.9";

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([%parameters])> - constructor

Create connection to database, run start queries, prepare statements.

Parameters as hash:

	* dsn - as in DBD::Pg
	* user - database user name
	* passwd - password
	* sets - start SQL queries (array reference)
	* preps - prepared statements (hash reference)

Example:

	my $db = NetSDS::DB->new(
		dsn => 'dbi:Pg:dbname=test',
		user => 'netsds',
		passwd => 'secret',
		sets => [
			"set search_path to myscheme",
			"insert into history (rec) values ('Client connected')",
		],
	);
	
=back

=cut

#-----------------------------------------------------------------------
sub new {
	my ( $class, %params ) = @_;

	my $dsn   = undef;
	my $attrs = {
				 pg_enable_utf8 => 1,
				 $params{attrs} ? %{$params{attrs}} : ()
				};
	my $sets  = $params{sets} || [];

	if ( $params{dsn} ) {
		# undocumented

		# DBI:CSV:f_dir=/home/joe/csvdb
		# DBI:mysql:webdb
		# DBI:Pg:dbname=web
		# DBI:Sybase:server=SYBASE;database=web
		# DBI:ODBC:MyDSN

		my $dsn_scheme   = undef;
		my $dsn_driver   = undef;
		my $dsn_attr_str = undef;
		my $dsn_attrs    = undef;
		my $dsn_dsn      = undef;
		if ( ( $dsn_scheme, $dsn_driver, $dsn_attr_str, $dsn_attrs, $dsn_dsn ) = DBI->parse_dsn( $params{dsn} ) ) {
			$dsn = sprintf( "%s:%s:%s", $dsn_scheme, $dsn_driver, $dsn_dsn );

			if ( 'Pg' eq $dsn_driver ) {
				unshift( @{$sets}, "SET CLIENT_ENCODING TO 'UTF-8'" );
				unshift( @{$sets}, "SET DATESTYLE TO 'ISO'" );
			}

			merge_hash( $attrs, $dsn_attrs );
		} else {
			return $class->error( "Can't parse DBI DSN: " . $params{dsn} );
		}
	} else {
		return $class->error( "Undefined DBI DSN: " . ( ref($class) || $class ) );
	}

	# Create object
	my $this = $class->SUPER::new(
		dbh    => undef,
		dsn    => '',
		user   => '',
		passwd => '',
		attrs  => {},
		preps  => {},
		sets   => [],
	);

	# Set authentication properties
	$this->dsn($dsn);
	$this->user( $params{user}     || '' );
	$this->passwd( $params{passwd} || '' );

	# Add prepered SQL statements
	$this->add_preps( %{ $params{preps} || {} } );

	# Add initialization SQL queries
	$this->add_sets( @{$sets} );

	$attrs->{PrintError} = 0;
	$this->add_attrs( %{$attrs} );

	# Connect to DBMS
	$this->connect();

	return $this;

} ## end sub new

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<dsn([$dsn])> - accessor to DSN

Paramters: (optional) new DSN if set

Returns: database DSN as string

Example:

	$this->dsn('dbi:Pg:dbname=kewldb');

=cut 

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('dsn');

#***********************************************************************

=item B<user([$username])> - user name

Paramters: (optional) new username

Returns: username

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('user');

#***********************************************************************

=item B<passwd()> - user password

This method provides accessor to password of DB connection handler. 

	print "Password is: " . $db->password();

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('passwd');

#***********************************************************************

=item B<attrs()> - connection attributes

Paramters:

Returns:

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('attrs');


#***********************************************************************

=item B<sets()> - initial SQL queries

This method provides accessor to SQL queries executed on connection time.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('sets');

#***********************************************************************

=item B<sets()> - accessor to prepared SQL statements

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('preps');

#***********************************************************************

=item B<dbh()> - DBI handler accessor

This method provides access to DBI handler for low level DBMS calls.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('dbh');

#***********************************************************************

=item B<add_sets()> - add initial SQL query

Example:

	$obj->add_sets("set search_path to myscheme");
	$obj->add_sets("set client_encoding to 'UTF-8'");

=cut

#-----------------------------------------------------------------------
sub add_sets {
	my ( $this, @sets ) = @_;

	push( @{ $this->sets }, @sets );

	return 1;
}

#***********************************************************************

=item B<add_attrs()> - add DBI handler attributes

	$this->add_attrs(AutoCommit => 1);

=cut

#-----------------------------------------------------------------------
sub add_attrs {
	my ( $this, %attrs ) = @_;

	return merge_hash( $this->attrs, \%attrs );
}

#***********************************************************************

=item B<add_preps()> - add prepared statements to class

	$this->add_preps(
		get_client => "select * from clients where id = ?",
		drop_client => "delete from clients where id = ?",
	);

=cut

#-----------------------------------------------------------------------
sub add_preps {
	my ( $this, %preps ) = @_;

	my $preps = $this->preps;
	while ( my ( $key, $query ) = each(%preps) ) {
		if ( $preps->{$key} ) {
			return $this->error( "Duplicate preparation: " . $key );
		} else {
			$preps->{$key} = [ $query, undef ];
		}
	}

	return 1;
}

#***********************************************************************

=item B<prepare()> - prepare statements

=cut

#-----------------------------------------------------------------------
sub prepare {
	my ($this) = @_;

	my $preps = $this->preps;
	my $dbh   = $this->dbh;
	while ( my ( $key, $query ) = each( %{$preps} ) ) {
		my $row = $preps->{$key};
		unless ( defined( $row->[1] ) ) {
			if ( my $sth = $dbh->prepare_cached( $row->[0] ) ) {
				$row->[1] = $sth;
			} else {
				return $this->error( $dbh->errstr || 'Prepare error' );
			}
		}
	}

	return 1;
}

#***********************************************************************

=item B<unprepare()> - finish and remove prepared SQL statements

Example:

	if ($need_to_stop) {
		$db->unprepare();
	}

=cut

#-----------------------------------------------------------------------
sub unprepare {
	my ($this) = @_;

	my $preps = $this->preps;
	my $dbh   = $this->dbh;
	while ( my ( $key, $query ) = each( %{$preps} ) ) {
		my $row = $preps->{$key};
		if ( defined( $row->[1] ) ) {
			$row->[1]->finish;
			$row->[1] = undef;
		}
	}

	return 1;
}

#***********************************************************************

=item B<connect()> - connect to DBMS

Try to connect to database if necessary.

=cut

#-----------------------------------------------------------------------
sub connect {
	my ($this) = @_;

	my $dbh = $this->dbh;
	unless ($dbh) {
		$dbh = DBI->connect_cached( $this->dsn, $this->user, $this->passwd, $this->attrs );

		if ($dbh) {
			$this->dbh($dbh);

			$this->error(undef);

			foreach my $row ( @{ $this->sets } ) {
				unless ( $dbh->do($row) ) {
					return $this->error( $dbh->errstr || 'Set error in connect' );
				}
			}

			unless ( $this->prepare ) {
				return undef;
			}
		} else {
			return $this->error( $DBI::errstr || 'Connect cached error' );
		}
	} ## end unless ($dbh)

	return $dbh;
} ## end sub connect

#***********************************************************************

=item B<disconnect()> - disconnect from DBMS

Disconnect from DBMS if necessary.

NOTE: Method does rollback for transactions if no C<AutoCommit> sttr

=cut

#-----------------------------------------------------------------------
sub disconnect {
	my ($this) = @_;

	my $dbh = $this->dbh;
	if ($dbh) {
		unless ( $dbh->{AutoCommit} ) {
			$dbh->rollback;
		}

		$this->unprepare;

		$dbh->disconnect;

		$this->dbh(undef);
	}

	return undef;
}

#***********************************************************************

=item B<ping([$reconnect])> - ping DBMS and reconnect if necessary

Method tries to ping() database calling DBI->ping() and returns C<DBI::db>
object if connection is alive.

Also this method provides reconnection if $reconnect parameter is C<TRUE>.

=cut

#-----------------------------------------------------------------------
sub ping {
	my ( $this, $reconnect ) = @_;

	my $dbh = $this->dbh;
	if ($dbh) {
		if ( $dbh->ping ) {
			return $dbh;
		} elsif ($reconnect) {
			$this->disconnect;

			$dbh = $this->connect;
		} else {
			$dbh = undef;
		}
	} elsif ($reconnect) {
		$dbh = $this->connect;
	} else {
		$dbh = undef;
	}

	return $dbh;
} ## end sub ping

#**************************************************************************

=item B<in_transaction()> - check if transaction in progress

Returns C<TRUE>, if DB connection is in transaction.

	0 - NOT in transaction
	1 - In transaction
	undef - undefined database handle

=cut

#-----------------------------------------------------------------------
sub in_transaction {
	my ($this) = @_;

	my $dbh = $this->dbh;
	return defined($dbh)
	  ? ( $dbh->{AutoCommit} )
	  ? 0
	  : 1
	  : undef;
}

#**************************************************************************

=item B<begin_transaction()> - start transaction

Example:

	$db->begin_transaction();

=cut

#-----------------------------------------------------------------------
sub begin_transaction {
	my ($this) = @_;

	my $dbh = $this->dbh;
	return defined($dbh)
	  ? ( $dbh->{AutoCommit} )
	  ? $dbh->begin_work
	  : 1
	  : undef;
}

#**************************************************************************

=item B<commit_transaction()> - commit transaction

Example:

	$db->commit_transaction();

=cut

#-----------------------------------------------------------------------
sub commit_transaction {
	my ($this) = @_;

	my $dbh = $this->dbh;
	return defined($dbh)
	  ? ( $dbh->{AutoCommit} )
	  ? 1
	  : $dbh->commit
	  : undef;
}

#**************************************************************************

=item B<rollback_transaction()> - rollback transaction

Eample:

	$db->begin_transaction();
	...
	do_some_db_changes;
	...
	if ($have_error_occured) {
		$db->rollback_transaction();
	} else {
		$db->commit_transaction();
	};

=cut

#-----------------------------------------------------------------------
sub rollback_transaction {
	my ($this) = @_;

	my $dbh = $this->dbh;
	return defined($dbh)
	  ? ( $dbh->{AutoCommit} )
	  ? 1
	  : $dbh->rollback
	  : undef;
}

#**************************************************************************

=item B<statement(KEY)> - return prepared SQL statement by key

	my $sth = $db->statement('drop_all_tables');
	$sth->execute(@params);

=cut

#-----------------------------------------------------------------------
sub statement {
	my ( $this, $key ) = @_;

	my $sth = $key;
	unless ( ref($key) ) {
		my $preps = $this->preps;
		if ( $preps->{$key} ) {
			$sth = $preps->{$key}->[1];
			unless ($sth) {
				unless ( $this->prepare ) {
					return undef;
				}
				$sth = $preps->{$key}->[1];
			}
		} else {
			$sth = $this->error( 'Unknown or undefined key for statement: ' . ( $key || '' ) );
		}
	}

	return $sth;
} ## end sub statement

#**************************************************************************

=item B<do_one(KEY[, @VALUES])> - call prepared SQL statement by key

Returns statement execution result.

	$db->do_one('drop_table', 'my_table');

=cut

#-----------------------------------------------------------------------
sub do_one {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( my $ret = $sth->execute(@_) ) {
			return $ret + 0;
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
}

#**************************************************************************

=item B<get_one(KEY[, @VALUES])> - return SQL query result as scalar

	my $msg_id = $db->get_one('find_msg_id', @filter);

=cut

#-----------------------------------------------------------------------
sub get_one {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			if ( my ($val) = $sth->fetchrow_array() ) {
				return $val;
			} else {
				return $this->error( "Fetching data error: " . $sth->errstr );
			}
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
} ## end sub get_one

#**************************************************************************

=item B<get_row_array(KEY[, @VALUES])> - fetch row as array

=cut

#-----------------------------------------------------------------------
sub get_row_array {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			if ( my $row = $sth->fetchrow_arrayref() ) {
				return $row;
			} else {
				return $this->error( "Fetching data error: " . $sth->errstr );
			}
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
} ## end sub get_row_array

#**************************************************************************

=item B<get_row_hash(KEY[, @VALUES])> - object method

=cut

#-----------------------------------------------------------------------
sub get_row_hash {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			if ( my $row = $sth->fetchrow_hashref() ) {
				return $row;
			} else {
				return $this->error( "Fetching data error: " . $sth->errstr );
			}
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
} ## end sub get_row_hash

#**************************************************************************

=item B<get_all_array(KEY[, @VALUES])> - fetch results as list of lists

=cut

#-----------------------------------------------------------------------
sub get_all_array {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			if ( my $all = $sth->fetchall_arrayref() ) {
				return $all;
			} else {
				return $this->error( "Fetching data error: " . $sth->errstr );
			}
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
} ## end sub get_all_array

#**************************************************************************

=item B<get_all_hash(KEY[, @VALUES])> - select as arrayref of hashrefs

=cut

#-----------------------------------------------------------------------
sub get_all_hash {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			my $list = [];
			while ( my $val = $sth->fetchrow_hashref() ) {
				push( @{$list}, $val );
			}
			return $list;

		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
} ## end sub get_all_hash

#**************************************************************************

=item B<get_col_array(KEY[, @VALUES])> - fetch results as list of lists

=cut

#-----------------------------------------------------------------------
sub get_col_array {
	my $this = shift(@_);
	my $key  = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			my $list = [];
			while ( my ($val) = $sth->fetchrow_array() ) {
				push( @{$list}, $val );
			}
			return $list;
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
} ## end sub get_col_array

#**************************************************************************

=item B<get_col_hash(KEY, FIELD[, @VALUES])> - fetch results as hash

This method allows fetch SQL query results as hash reference.

=cut

#-----------------------------------------------------------------------
sub get_col_hash {
	my $this  = shift(@_);
	my $key   = shift(@_);
	my $field = shift(@_);

	$this->error(undef);

	my $sth = $this->statement($key);
	if ($sth) {
		if ( $sth->execute(@_) ) {
			return $sth->fetchall_hashref($field);
		} else {
			return $this->error( "Execution statement error: " . $sth->errstr );
		}
	}

	return undef;
}

#***********************************************************************

=item B<do($SQL)> - execute SQL query

Paramters: SQL query string

Returns: result of query

This method is proxy for C<DBI::do> method.

=cut 

#-----------------------------------------------------------------------

sub do {
	my $this = shift(@_);
	return $this->dbh->do(@_);
}

sub selectall_arrayref {
	my $this = shift(@_);
	return $this->dbh->selectall_arrayref(@_);
}

sub selectall_hashref {
	my $this = shift(@_);
	return $this->dbh->selectall_hashref(@_);
}

sub selectcol_arrayref {
	my $this = shift(@_);
	return $this->dbh->selectcol_arrayref(@_);
}

sub selectrow_array {
	my $this = shift(@_);
	return $this->dbh->selectrow_array(@_);
}

sub selectrow_arrayref {
	my $this = shift(@_);
	return $this->dbh->selectrow_arrayref(@_);
}

sub selectrow_hashref {
	my $this = shift(@_);
	return $this->dbh->selectrow_hashref(@_);
}

#***********************************************************************

=item B<quote($param)> - string SQL quoting

This method is a proxy for C<DBI::quote> method.

	my $quote_string = $db->quote($unquoted_string);

=cut 

#-----------------------------------------------------------------------

sub quote {
	my $this = shift(@_);
	return $this->dbh->quote(@_);
}

1;

__END__

=back

=head1 EXAMPLES

Nothing yet

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Valentyn Solomko <val@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


