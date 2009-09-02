use strict;
use warnings;

use Net::SMTP;
use Test::More tests => 9;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

my $package = 'NetSDS::App::SMTPD';
use_ok($package);

my ($pid, $port) = (fork, 2525);

if ($pid == 0) {
	NetSDS::App::SMTPD->run(  infinite  => 1,
		                      debug     => 1,
		                      verbose   => 1,
		                      port      => $port
	);

} else {
	
	my $smtp = new Net::SMTP "localhost:$port", Debug => 0;
	ok($smtp, 'checking that we can connect to our server'); 
	ok($smtp->mail("yana\@mail.ua"), 'initialize sending mail');
	ok($smtp->to("postmaster"), 'set to');
	ok($smtp->data, 'initialize sending data');
	ok($smtp->datasend("To: postmaster\n"), 'set header TO');
	$smtp->datasend("\n");
	ok($smtp->datasend("A simple test message\n"), 'send a simple message');
	ok($smtp->dataend, 'dataend');
	ok($smtp->quit, 'quit');

	kill 'INT', $pid;
};
