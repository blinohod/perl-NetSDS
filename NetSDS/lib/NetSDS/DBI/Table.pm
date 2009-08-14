#===============================================================================
#
#         FILE:  Table.pm
#
#  DESCRIPTION:  NetSDS::DBI::Table - CRUD implementation for NetSDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  25.07.2008 01:06:46 EEST
#===============================================================================

=head1 NAME

NetSDS::DBI::Table

=head1 SYNOPSIS

	use NetSDS::DBI::Table;

	my $q = NetSDS::DBI::Table->new(
		dsn    => 'dbi:Pg:dbname=netsdsdb;host=127.0.0.1',
		user   => 'netsds',
		passwd => 'test',
		table  => 'public.messages',
	) or warn NetSDS::DBI::Table->errstr();


=head1 DESCRIPTION

C<NetSDS::DBI::Table> module provides commonly used CRUD functionality for
data stored in single database.

Main idea was that we can agree about some limitations:

* every such table contains C<id> field that is primary key

* we use PostgreSQL DBMS with all it's features

=cut

package NetSDS::DBI::Table;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::DBI';

use version; our $VERSION = "0.002";

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([...])> - class constructor

	my $tbl = NetSDS::DBI::Table->new(
		dsn => 'dbi:Pg:dbname=content',
		login => 'netsds',
		passwd => 'topsecret,
		table => 'content.meta',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# Initialize base DBMS connector
	my $this = $class->SUPER::new(%params);

	# Set table name
	if ( $params{table} ) {
		$this->{table} = $params{table};
	} else {
		return $class->error('Table name is not specified to NetSDS::DBI::Table');
	}

	return $this;

}

#***********************************************************************

=item B<fetch(%params)> - get records from table as array of hashrefs

Paramters (hash):

* fields - fetch fields by list

* filter - arrayref of SQL expressions like C<status = 'active'> for C<WHERE> clause

* order - arrayref of SQL expressions like C<id desc> for C<ORDER BY> clause

* limit - max number of records to fetch (LIMIT N)

* offset - records to skip from beginning (OFFSET N)

* for_update - records selected for further update within current transaction

Returns: message as array of hashrefs

Sample:

	my @messages = $q->fetch(
		fields => ['id', 'now() as time'],
		filter => ['msg_status = 5', 'date_received < now()'], # where msg_status=5 and date_received < now()
		order  => ['id desc', 'src_addr'], # order by id desc, src_addr
		limit => 3, # fetch 3 records
		offset => 5, # from 6-th record
		for_update => 1, # for update
	)

=cut 

#-----------------------------------------------------------------------

sub fetch {

	my ( $this, %params ) = @_;

	# Prepare fields list
	my @fields = ();
	if ( $params{fields} ) {
		@fields = @{ $params{fields} };
	}
	my $fields_q = "*";
	if (@fields) {
		$fields_q = join( ", ", @fields );
	}

	# Prepare filtering rules
	my @filter = ();
	if ( $params{filter} ) {
		@filter = @{ $params{filter} };
	}
	my $where_q = "";
	if (@filter) {
		$where_q = " where " . join( " and ", @filter );
	}

	# Prepare ordering rules
	my @order = ();
	if ( $params{order} ) {
		@order = @{ $params{order} };
	}
	my $order_q = "";
	if (@order) {
		$order_q = " order by " . join( ", ", @order );
	}

	# Set limit and offset for fetching
	my $limit_q  = "";
	my $offset_q = "";
	if ( $params{limit} ) {
		$limit_q = " limit " . $params{limit};
		if ( $params{offset} ) {
			$offset_q = " offset " . $params{offset};
		}
	}

	# Request for messages
	my $sql = "select $fields_q from " . $this->{table} . " $where_q $order_q $limit_q $offset_q";

	# Set FOR UPDATE if necessary
	if ( $params{for_update} ) {
		$sql .= " for update";
	}

	my @ret = ();
	my $sth = $this->call($sql);
	$sth->execute();
	while ( my $row = $sth->fetchrow_hashref() ) {
		push @ret, $row;
	}

	return @ret;

} ## end sub fetch

#***********************************************************************

=item B<insert(%key_val_pairs)> - insert record into table

Paramters: record fields as hash

Returns: id of inserted record 

	my $user_id = $tbl->insert_row(
		'login' => 'vasya',
		'password' => $encrypted_passwd,
	);

=cut 

#-----------------------------------------------------------------------

sub insert_row {

	my ( $this, %params ) = @_;

	my @fields = ();    # Fields list
	my @values = ();    # Values list

	# Prepare fields and values lists from input hash
	foreach my $key ( keys %params ) {
		push @fields, $key;
		push @values, $this->dbh->quote( $params{$key} );
	}

	# Prepare SQL statement from fields and values lists
	my $sql = 'insert into ' . $this->{table} . ' (' . join( ',', @fields ) . ')'    # fields list
	  . ' values (' . join( ',', @values ) . ')'                                     # values list
	  . ' returning id';                                                             # return "id" field

	# Execute SQL query and fetch result
	my ($row_id) = $this->call($sql)->fetchrow_array();

	# Return "id" field from inserted row
	return $row_id || $this->error( "Cant insert table record: " . $this->dbh->errstr );

} ## end sub insert_row

#***********************************************************************

=item B<insert(@records_list)> - mass insert

Paramters: list of records (as hashrefs)

Returns: array of inserted records "id"

This method allows mass insert of records.

	my @user_ids = $tbl->insert(
		{ login => 'vasya', password => $str1 },
		{ login => 'masha', password => $str2 },
		{ login => 'petya', password => $str3, active => 'false' },
	);

B<Warning!> This method use separate INSERT queries and in fact is only
wrapper for multiple C<insert_row()> calls. So it's not so fast as
one insert but allows to use different key-value pairs for different records.

=cut 

#-----------------------------------------------------------------------

sub insert {

	my ( $this, @rows ) = @_;

	my @ids = ();

	# Go through records and insert each one
	foreach my $rec (@rows) {
		push @ids, ( $this->insert_row( %{$rec} ) );
	}

	return @ids;

}

#***********************************************************************

=item B<update($id, %params)> - update record parameters

Paramters: id, new parameters as hash

Returns: updated record as hash

Example:


	my %upd = $table->update($msg_id,
		status => 'failed',
		dst_addr => '380121234567',
		);


After this %upd hash will contain updated table record.

=cut 

#-----------------------------------------------------------------------

sub update {

	my ( $this, $id, %params ) = @_;
	my @up = ();
	foreach my $key ( keys %params ) {
		push @up, "$key = " . $this->_quote( $params{$key} );
	}

	my $sql = "update " . $this->{table} . " set " . join( ', ', @up ) . " where id=$id returning *";
	#warn "UPDATE: $sql";
	my $res = $this->selectrow_hashref($sql);

	if ($res) {
		return %{$res};
	} else {
		return $this->error( "Cant update message" . $this->dbh->errstr );
	}

}
#***********************************************************************

=item B<get_count()> - retrieve number of contacts

Just return total number of contacts by calling:

	SELECT COUNT(*) FROM cpa.table

=cut 

#-----------------------------------------------------------------------

## Returns number of records
sub get_count {

	my $this   = shift;
	my %params = @_;

	$params{fields} = ["COUNT(*) AS c"];
	my @count = $this->fetch(%params);

	return $count[0]->{c};
}

#***********************************************************************

=item B<delete($id)> - delete record from table

Paramters: record id

Returns: 1 if ok, undef if error

Method deletes record from database table by it's identifier

=cut 

#-----------------------------------------------------------------------

sub delete {

	my $this = shift;
	my @id   = @_;

	# TODO: check for too long @id list
	my $id_in = "id IN (" . join( ", ", @id ) . ")";
	my $sql   = "delete from " . $this->{table} . " where $id_in";

	if ( $this->do($sql) ) {
		return 1;
	} else {
		return $this->error( "Can't delete record: table='" . $this->{table} . "', $id_in'; " . $this->dbh->errstr );
	}

}

1;

__END__

=back

=head1 EXAMPLES

See C<samples/test_db_table.pl> script

=head1 BUGS

Bad documentation

=head1 SEE ALSO

L<NetSDS::DBI>
L<http://en.wikipedia.org/wiki/Create,_read,_update_and_delete>

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


