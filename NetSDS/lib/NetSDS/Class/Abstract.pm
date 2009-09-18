#===============================================================================
#
#         FILE:  Abstract.pm
#
#  DESCRIPTION:  Abstract Class for other NetSDS code
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  24.04.2008 11:42:42 EEST
#===============================================================================

=head1 NAME

NetSDS::Class::Abstract - superclass for all NetSDS APIs

=head1 SYNOPSIS

	package MyClass;
	use base 'NetSDS::Class::Abstract';

	__PACKAGE__->mk_accessors(qw/my_field/);

	sub error_sub {
		my ($self) = @_;
		if (!$self->my_field) {
			return $self->error("No my_field defined");
		}
	}

	1;

=head1 DESCRIPTION

C<NetSDS::Class::Abstract> is a superclass for all other NetSDS classes, containing the following functionality:

=over

=item * common class constructor

=item * safe modules inclusion

=item * class and objects accessors and cloning;

=item * error handling;

=back

All other class/object APIs should inherit this class to use it's functionality in standard way.

=cut

package NetSDS::Class::Abstract;

use 5.8.0;
use strict;
use warnings;

use base qw(
  Clone
  Class::Accessor
  Class::Accessor::Class
  Class::ErrorHandler
);

use Storable qw(nfreeze thaw);

use Data::Structure::Util;


use version; our $VERSION = '1.205';

#***********************************************************************

=head1 CONSTRUCTOR, INITIALIZATION, APPLICATION

=over

=item B<new([...])>

Common constructor for NetSDS classes.

    my $object = NetSDS::SomeClass->new(%options);

Constructor may be overwriten in inherited classes and usually is.
Parameters for constructor may be given as hash or hash reference.

=cut

#-----------------------------------------------------------------------
sub new {

	my ($proto) = shift(@_);
	my $class = ref($proto) || $proto;

	my $self = undef;
	my $cnt  = scalar(@_);

	if ( $cnt == 0 ) {
		$self = {};
	} elsif ( ( $cnt == 1 ) and ( ref( $_[0] ) eq 'HASH' ) ) {
		$self = { %{ $_[0] } };
	} elsif ( ( $cnt & 1 ) == 0 ) {
		my %params = @_;
		$self = \%params;
	} else {
		$class->error( "Wrong parameters for constructor: " . $cnt );
	}

	bless( $self, $class );

	return $self;

} ## end sub new

#***********************************************************************

=item B<mk_class_var(@variables)>

    Class->mk_class_var(@variables);

This creates accessor/mutator methods for each named class variable.


=cut

#-----------------------------------------------------------------------
sub mk_class_var {
	my $self  = shift(@_);
	my $class = ref($self) || $self;

	foreach my $name (@_) {
		my $var = uc($name);

		my $sub = sub {
			my $self  = shift(@_);
			my $class = ref($self) || $self;

			if (@_) {
				no strict 'refs';

				${ sprintf( '%s\::%s', $class, $var ) } = $_[0];

				return $_[0];
			} else {
				no strict 'refs';

				return ${ sprintf( '%s\::%s', $class, $var ) };
			}
		};

		no strict 'refs';

		*{ sprintf( '%s::%s', $class, lc($name) ) } = $sub;
	} ## end foreach my $name (@_)

} ## end sub mk_class_var

#***********************************************************************

=item B<use_modules(ARRAY)>

Invoke modules from list given in parameters.

Return C<TRUE> in case of success or C<FALSE> if failed.

=cut

#-----------------------------------------------------------------------
sub use_modules {

	my $self = shift(@_);

	foreach my $mod (@_) {
		eval "use $mod;";
		if ($@) {
			$self->last_error($@);
			return undef;
		}
	}

	return 1;

}

#***********************************************************************

=item B<unbless()>

Return non object copy of object data structure.

	$copy = $obj->unbless();
	$same = $obj->unbless( 1 );

=cut

#-----------------------------------------------------------------------
sub unbless {

	my ( $self, $ret_self ) = @_;

	return Data::Structure::Util::unbless( $ret_self ? $self : $self->clone );
}

#***********************************************************************

=item B<serialize()> - returns serialized object

This method returns serialized copy of object.

=cut 

#-----------------------------------------------------------------------

sub serialize {

	my ($self) = @_;

	return nfreeze($self);
}

#***********************************************************************

=item B<deserialize($serialized)> - returns deserialized object

Paramters: serialized object as string

Returns: object

	my $obj = NetSDS::SomeClass->deserialize($str);

=cut 

#-----------------------------------------------------------------------

sub deserialize {

	my ( $proto, $ser ) = @_;

	my $obj = undef;

	eval { $obj = thaw($ser); };

	if ($@) {
		return undef;
	} else {
		return $obj;
	}

}

#***********************************************************************

=item B<nstore($file_name)> - store serialized object

Save serialized object to file

=cut 

#-----------------------------------------------------------------------

sub nstore {

	my ( $self, $fname ) = @_;

	Storable::nstore( $self, $fname );
}

#***********************************************************************

=item B<logger()> - set logger handler

This method allows to set class logger (NetSDS::Logger object)

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('logger');    # Logger

#***********************************************************************

=item B<log($level, $message)> - write log message

Paramters: log level, log message

	$obj->log("info", "We still alive");

=cut 

#-----------------------------------------------------------------------

sub log {

	my ( $self, $level, $msg ) = @_;

	if ( $self->logger() ) {
		$self->logger->log( $level, $msg );
	} else {
		warn "[$level] $msg\n";
	}
}

#***********************************************************************

=item B<error_code($new_code)> - set/get error code

	if (error_occured()) {

		$self->error_code(1234); # secret error status
		return $self->error("Oops! We have a 1234 error!");

	}

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_class_accessors('error_code');

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory and other C<NetSDS> moduleis for examples of code.

=head1 SEE ALSO

L<Class::Accessor>, L<Class::Accessor::Class>, L<Clone>, L<Class::ErrorHandler>

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

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


