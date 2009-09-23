use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More tests => 37;

use Data::Dumper;
use Data::UUID;

use lib "$Bin/../lib";

my $package = 'NetSDS::Session';
use_ok($package);

my @session = map { 
	my $ug = Data::UUID->new; $ug->to_string($ug->create) 
} 1..3;

my $session = $package->new(
	host => '127.0.0.1',
	port => 11211
);

for my $session_id (@session) {
	ok($session->set_session($session_id), "create session with id [$session_id]");
	ok($session->set($session_id, $session_id x 3), "set a key to session");
	ok($session->close_session, "store session");
};

for my $session_id (@session) {
	ok($session->set_session($session_id), "get existed session");
	cmp_ok($session->get($session_id), "eq", $session_id x 3, 
		"checking if the session value is the same");
	ok($session->set($session_id, 'changed'), 'change the value');
	ok($session->close_session, "store_session");
};

for my $session_id (@session) {
	ok($session->set_session($session_id), "get existed session");
	cmp_ok($session->get($session_id), "eq", 'changed', 
		"checking if the session value has been changed");
	ok($session->clear, "clear session");
};

for my $session_id (@session) {
	ok($session->set_session($session_id), "get existed session");
	ok(!$session->get($session_id), "check the value of a session that has been deleted");
};
