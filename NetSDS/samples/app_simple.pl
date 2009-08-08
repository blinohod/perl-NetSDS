#!/usr/bin/env perl 

=head1 SYNOPSIS

Options:

	--help - this message
	--version - show application version
	--verbose - increase verbosity level
	--daemon - run as daemon

C<app_simple.pl> is an example for NetSDS application developers.

=cut

use version; our $VERSION = "1.001";

MyApp->run( infinite => 1, daemon => 0, has_conf => 0, verbose => 1 );

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
