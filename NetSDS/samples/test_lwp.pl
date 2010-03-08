#!/usr/bin/env perl 

use warnings;
use strict;

use lib '../lib';

use NetSDS::LWP;
use Data::Dumper;

my $lwp = NetSDS::LWP->new();

# Test simple HTTP GET request
my $res = $lwp->get_simple(
	'http://ajax.googleapis.com/ajax/services/language/translate',
	v        => '1.0',
	q        => 'Fall down',
	langpair => 'en|ru',
);

print $res;

# Test simple HTTP GET request with JSON response
$res = $lwp->get_json(
	'http://ajax.googleapis.com/ajax/services/language/translate',
	v        => '1.0',
	q        => 'Fall down',
	langpair => 'en|ru',
);

print Dumper($res);

1;
