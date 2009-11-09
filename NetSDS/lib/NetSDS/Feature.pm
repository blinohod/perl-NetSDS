#===============================================================================
#
#         FILE:  Feature.pm
#
#  DESCRIPTION:  Abstract application feature class.
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (RATTLER), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  14.09.2008 12:32:03 EEST
#===============================================================================

=head1 NAME

NetSDS::Feature - abstract application feature

=head1 SYNOPSIS

	package NetSDS::Feature::DBI;

	use DBI;
	use base 'NetSDS::Feature';

	sub init {
		my ($self) = @_;

		my $dsn = $self->conf->{dsn};
		my $user = $self->conf->{user};
		my $passwd = $self->conf->{passwd};

		$self->{dbconn} = DBI->connect($dsn, $user, $passwd);

	}

	# Sample method - DBI::do proxy
	sub do {

		my $self = shift @_;
		return $self->{dbconn}->do(@_);
	}

	1;


=head1 DESCRIPTION

Application C<features> are Perl5 packages with unified API for easy
integration of some functionality into NetSDS applications infrastructure.

C<NetSDS::Feature> module contains superclass for application features
providing the following common feature functionality:

	* class construction
	* initialization stub
	* logging

=cut

package NetSDS::Feature;

use 5.8.0;
use strict;
use warnings;

use base qw(Class::Accessor Class::ErrorHandler);


use version; our $VERSION = '1.300';

#===============================================================================

=head1 CLASS METHODS

=over

=item B<create($app, $conf)> - feature constructor


=cut

#-----------------------------------------------------------------------
sub create {

	my ( $class, $app, $conf ) = @_;

	my $self = {
		app  => $app,
		conf => $conf,
	};

	bless $self, $class;

	$self->init();

	return $self;

}

#***********************************************************************

=item B<init()> - feature initialization 

This method should be rewritten with feature functionality implementation.

=cut 

#-----------------------------------------------------------------------

sub init {

	my ($self) = @_;

}

#***********************************************************************


=back

=head1 OBJECT METHODS

=over

=item B<app()> - application object 

This method allows to use application methods and properties. 

	print "Feature included from app: " . $self->app->name;

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_ro_accessors('app');

#***********************************************************************

=item B<conf()> - feature configuration

This method provides access to feature configuration.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_ro_accessors('conf');

#***********************************************************************

=item B<log($level, $message)> - implements logging

Example:

	# Write log message
	$self->log("info", "Application does something interesting.");

See L<NetSDS::Logger> documentation for details.

=cut 

#-----------------------------------------------------------------------

sub log {

	my ($self) = shift @_;

	return $self->app->log(@_);

}

1;

__END__

=back

=head1 EXAMPLES

See C<samples/app_features.pl> script.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<NetSDS::App>

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


