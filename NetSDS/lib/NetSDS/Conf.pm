
=head1 NAME

NetSDS::Conf - API to configuration files

=head1 SYNOPSIS

	use NetSDS::Conf;

	my $cf = NetSDS::Conf->getconf($conf_file);
	my $val = $cf->{'parameter'};

=head1 DESCRIPTION

B<NetSDS::Conf> module is a wrapper to B<Config::General> handler for
NetSDS configuration files.

This package is for internal usage and is called from B<NetSDS::App>
or inherited modules and should be never used directly from applications.

=cut

package NetSDS::Conf;

use 5.8.0;
use strict;
use warnings;

use NetSDS::Exceptions;
use Config::General;

use version; our $VERSION = version->declare('v3.0.0');

#***********************************************************************

=over

=item B<getconf()> - read parameters from configuration file

Paramters: configuration file name

Returns: cofiguration as hash reference

This method tries to read configuration file and fill object properties
with read values.

NOTE: Parameters set from command line will not be overriden.

=cut 

#-----------------------------------------------------------------------

sub getconf {

	my ( $proto, $cf ) = @_;

	# Check if configuration file name is set.
	unless ($cf) {
		NetSDS::Exception::Config->throw( message => 'Configuration file name not set.' );
	}

	# Check if configuration file exists and is available for reading
	unless ( ( -f $cf ) or ( -r $cf ) ) {
		NetSDS::Exception::Config->throw( message => 'Configuration file not exists or is not readable: ' . $cf );
	}

	# Read configuration file
	my $conf = Config::General->new(
		-ConfigFile        => $cf,
		-AllowMultiOptions => 'yes',
		-UseApacheInclude  => 'yes',
		-InterPolateVars   => 'yes',
		-ConfigPath        => [ $ENV{NETSDS_CONF_DIR}, '/etc/NetSDS' ],
		-IncludeRelative   => 'yes',
		-IncludeGlob       => 'yes',
		-UTF8              => 'yes',
	);

	unless ( ref $conf ) {
		NetSDS::Exception::Config->throw( message => 'Configuration file parsing error' );
	}

	# Fetch parsed configuration
	my %cf_hash = $conf->getall or ();

	return \%cf_hash;

} ## end sub getconf

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown

=head1 SEE ALSO

L<Config::General>

=head1 TODO

1. Improve documentation.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


