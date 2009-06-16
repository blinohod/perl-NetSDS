#!/usr/bin/env perl 

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use NetSDS::DB::Table;

# Create table handler
my $q = NetSDS::DB::Table->new(
	dsn    => 'dbi:Pg:dbname=gmf1;host=127.0.0.1',
	user   => 'postgres',
	passwd => 'test',
	table  => 'public.messages',
  )
  or warn NetSDS::DB::Table->errstr();

print Dumper($q);

# Read records from table
print Dumper(
	$q->fetch(
		filter => ['msg_status = 5', 'date_received < now()'],
		order  => ['id desc', 'src_addr'],
		limit => 3,
	)
);

# Insert record into table
my %new = $q->insert(
		src_addr => '3801234567',
		dst_addr => '333',
		src_app_id => 1,
);

print Dumper(\%new);

1;

