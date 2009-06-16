#!/usr/bin/env perl 

MyApp->run( daemon => 0, has_conf => 0 );

1;

package MyApp;

use 5.8.0;
use warnings;
use strict;

# Inherits NetSDS::App features
use base 'NetSDS::App';

sub start {
	my ($this) = @_;
	print "Application started: name=" . $this->name . "\n";
	if ( $this->debug ) { print "We are under debug!\n"; }
}

sub process {
	my ($this) = @_;

	for ( my $i = 1 ; $i <= 3 ; $i++ ) {

		# Do something and add messages to syslog
		print "PID=" . $this->pid . "; iteration: $i\n";
		$this->log( "info", "My PID: " . $this->pid . "; iteration: $i" );
		sleep 1;
	}
}

sub stop {
	my ($this) = @_;
	print "Finishing application at last. Bye! :-)\n";
}

1;
