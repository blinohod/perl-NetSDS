#!/usr/bin/env perl 

use Data::Dumper;

use NetSDS::Auth;

my $auth = NetSDS::Auth->new(
	dsn => 'dbi:Pg:dbname=netsds',
	user => 'misha',
	passwd => '',
);

my $data = $auth->auth_user('misha', 'Secret', 'admin');
print Dumper($data);
print Dumper($auth);

print "SESS: " . $auth->_gen_session();

1;
