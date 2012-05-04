
=head1 NAME

NetSDS::Class::Abstract - superclass for all NetSDS APIs

=head1 SYNOPSIS

	package MyClass;
	use base 'NetSDS::Class::Abstract';

	__PACKAGE__->mk_accessors(qw/my_field/);

	1;

=head1 DESCRIPTION

C<NetSDS::Class::Abstract> is a superclass for all other NetSDS classes, containing the following functionality:

=over

=item * common class constructor

=item * safe modules inclusion

=item * class and objects accessors 

=item * logging

=back

All other class/object APIs should inherit this class to use it's functionality in standard way.

=cut

package NetSDS::Class::Abstract;

use 5.8.0;
use strict;
use warnings;

use diagnostics -traceonly;

use mro 'c3';

use base 'Class::Accessor::Class';

use NetSDS::Exceptions;

use version; our $VERSION = version->declare('v3.0.0');

#***********************************************************************

=head1 CONSTRUCTOR, INITIALIZATION, APPLICATION

=over

=item B<new(%params)> - common constructor

C<new()> method implements common constructor for NetSDS classes.
Constructor may be overwriten in inherited classes and usually
this happens to implement module specific functionality.

Constructor requres parameters as hash that are set as object properties.

	my $object = NetSDS::SomeClass->new(
		foo => 'abc',
		bar => 'def',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $proto, %params ) = @_;

	my $class = ref($proto) || $proto;

	my $this = \%params;

	bless( $this, $class );

	return $this;

}

#***********************************************************************

=item B<mk_class_accessors(@properties)> - class properties accessor

See L<Class::Accessor> for details.

	__PACKAGE__->mk_class_accessors('foo', 'bar');

=item B<mk_accessors(@propertire)> - object properties accessors

See L<Class::Accessor::Class> for details.

	$this->mk_accessors('foo', 'bar');

Other C<Class::Accessor::Class> methods available as well.

=cut 

#-----------------------------------------------------------------------

#***********************************************************************

=item B<use_modules(@modules_list)> - load modules on demand

C<use_modules()> provides safe on demand modules loader.
It requires list of modules names as parameters

In case of error throws exception.

Example:

	# Load modules for daemonization
	if ($daemon_mode) {
		$this->use_modules("Proc::Daemon", "Proc::PID::File");
	}

=cut

#-----------------------------------------------------------------------
sub use_modules {

	my $this = shift(@_);

	foreach my $mod (@_) {
		eval "use $mod;";
		if ($@) {
			NetSDS::Exception::Generic->throw( error => $@ );
		}
	}

	return 1;

}

#***********************************************************************

=back

=head1 LOGGING

=over

=item B<logger()> - get/set logging handler

C<logger> property is an object that should provide functionality
handling log messaging. Usually it's object of L<NetSDS::Logger>
class or C<undef>. However it may another object implementing
non-standard features like sending log to e-mail or to DBMS.

Example:

	# Set logger and send log message
	$obj->logger(NetSDS::Logger->new());
	$obj->log("info", "Logger connected");

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_class_accessors('logger');    # Logger

#***********************************************************************

=item B<log($level, $message)> - write log message

Paramters: log level, log message

Example:

	$obj->log("info", "We still alive");

=cut 

#-----------------------------------------------------------------------

sub log {

	my ( $this, $level, $msg ) = @_;

	# Logger expected to provide "log()" method
	if ( $this->logger() and $this->logger()->can('log') ) {
		$this->logger->log( $level, $msg );
	} else {
		warn "[$level] $msg\n";
	}
}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory and other C<NetSDS> moduleis for examples of code.

=head1 SEE ALSO

L<Class::Accessor::Class>

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2012 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


