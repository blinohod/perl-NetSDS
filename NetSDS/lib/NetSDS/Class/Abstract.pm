#===============================================================================
#
#         FILE:  Abstract.pm
#
#  DESCRIPTION:  Abstract Class for other NetSDS code
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  24.04.2008 11:42:42 EEST
#===============================================================================

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


use version; our $VERSION = '1.202';

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

	my $this = undef;
	my $cnt  = scalar(@_);

	if ( $cnt == 0 ) {
		$this = {};
	} elsif ( ( $cnt == 1 ) and ( ref( $_[0] ) eq 'HASH' ) ) {
		$this = { %{ $_[0] } };
	} elsif ( ( $cnt & 1 ) == 0 ) {
		my %params = @_;
		$this = \%params;
	} else {
		$class->error( "Wrong parameters for constructor: " . $cnt );
	}

	bless( $this, $class );

	return $this;

} ## end sub new

#***********************************************************************

=item B<mk_class_var(@variables)>

    Class->mk_class_var(@variables);

This creates accessor/mutator methods for each named class variable.


=cut

#-----------------------------------------------------------------------
sub mk_class_var {
	my $this  = shift(@_);
	my $class = ref($this) || $this;

	foreach my $name (@_) {
		my $var = uc($name);

		my $sub = sub {
			my $this  = shift(@_);
			my $class = ref($this) || $this;

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

	my $this = shift(@_);

	foreach my $mod (@_) {
		eval "use $mod;";
		if ($@) {
			$this->last_error($@);
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

	my ( $this, $self ) = @_;

	return Data::Structure::Util::unbless( $self ? $this : $this->clone );
}

#***********************************************************************

=item B<serialize()> - returns serialized object

This method returns serialized copy of object.

=cut 

#-----------------------------------------------------------------------

sub serialize {

	my ($this) = @_;

	return nfreeze($this);
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

	my ( $this, $fname ) = @_;

	Storable::nstore( $this, $fname );
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

	my ( $this, $level, $msg ) = @_;

	if ( $this->logger() ) {
		$this->logger->log( $level, $msg );
	} else {
		warn "[$level] $msg\n";
	}
}

#***********************************************************************

=item B<error_code($new_code)> - set/get error code

	if (error_occured()) {

		$this->error_code(1234); # secret error status
		return $this->error("Oops! We have a 1234 error!");

	}

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_class_accessors('error_code');

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory and other C<NetSDS> moduleis for examples of code.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<Class::Accessor>, L<Class::Accessor::Class>, L<Clone>, L<Class::ErrorHandler>

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


