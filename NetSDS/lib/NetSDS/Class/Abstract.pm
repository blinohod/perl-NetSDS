
=head1 NAME

NetSDS::Class::Abstract - superclass for all NetSDS APIs

=head1 SYNOPSIS

	package MyClass;
	use base 'NetSDS::Class::Abstract';

	__PACKAGE__->mk_accessors(qw/my_field/);

	sub error_sub {
		my ($this) = @_;
		if (!$this->my_field) {
			return $this->error("No my_field defined");
		}
	}

	1;

=head1 DESCRIPTION

C<NetSDS::Class::Abstract> is a superclass for all other NetSDS classes, containing the following functionality:

=over

=item * common class constructor

=item * safe modules inclusion

=item * class and objects accessors 

=item * logging

=item * error handling;

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

# Error handling class variables
our $_ERRSTR;     # error string
our $_ERRCODE;    # error code

use version; our $VERSION = version->declare('v2.3.0');

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

Return 1 in case of success or C<undef> if faied. Error messages in case
of failure are available using C<errstr()> call.

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
			return $this->error($@);
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

#***********************************************************************

=back

=head1 ERROR HANDLING

C<NetSDS::Class::Abstract> provides common instruments for handling
errors in more intelligent way than just return flase value.

When some subroutine should return error, it is recommended to use C<error()>
method with mentioning error message and optional code.

=over

=item B<error($msg, [$code])> - set error message and code

C<error()> method set error message and optional error code.
It can be invoked in both class and object contexts.

Example 1: set class error

	return NetSDS::Foo->error("Mistake found");

Example 2: set object error with code

	return $obj->error("Can't launch rocket", BUG_STUPID);

=cut

#-----------------------------------------------------------------------

sub error {

	my ( $this, $msg, $code ) = @_;

	$msg  ||= '';    # error message
	$code ||= '';    # error code

	if ( ref($this) ) {
		$this->{_errstr}  = $msg;
		$this->{_errcode} = $code;
	} else {
		$_ERRSTR  = $msg;
		$_ERRCODE = $code;
	}

	return undef;
}

#***********************************************************************

=item B<errstr()> - retrieve error message

C<errstr()> method returns error string in both object and class contexts.

Example:

	warn "We have an error: " . $obj->errstr;

=cut

#-----------------------------------------------------------------------

sub errstr {

	my $this = shift;
	return ref($this) ? $this->{_errstr} : $_ERRSTR;

}

#***********************************************************************

=item B<errcode()> - retrieve error code

C<errcode()> method returns error code in both object and class contexts. 

Example:

	if ($obj->errcode == 42) {
		print "Epic fail! We've found an answer!";
	}

=cut

#-----------------------------------------------------------------------

sub errcode {

	my $this = shift;
	return ref($this) ? $this->{_errcode} : $_ERRCODE;

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


