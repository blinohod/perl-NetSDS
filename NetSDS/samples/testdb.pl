#!/usr/bin/env perl 
use 5.8.0;
use strict;
use warnings;

use NetSDS::DBI;
use Data::Dumper;

my $db = NetSDS::DBI->new(
	dsn    => 'dbi:Pg:dbname=test_netsds;host=127.0.0.1;port=5432',
	login  => 'netsds',
	passwd => '',
);

print Dumper($db);

#print Dumper($db->dbh->selectrow_hashref("select md5('sdasd')"));
print $db->call("select md5(?)", 'zuka')->fetchrow_hashref->{md5};

1;
