#===============================================================================
#
#         FILE:  EDR.pm
#
#  DESCRIPTION:  Module for reading/writing Event Details Records
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  28.08.2009 16:43:02 EEST
#===============================================================================

=head1 NAME

NetSDS::EDR - read/write Event Details Records

=head1 SYNOPSIS

	use NetSDS::EDR;

	my $edr = NetSDS::EDR->new(
		filename => '/mnt/billing/call-stats.dat',
	);

	...

	$edr->write(
		{
		callerid => '80441234567',
		clip => '89001234567',
		start_time => '2006-12-55 12:21:46',
		end_time => '2008-12-55 12:33:22'
		}
	);

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::EDR;

use 5.8.0;
use strict;
use warnings;

use JSON;
use NetSDS::Util::DateTime;
use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = '1.205';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

    my $edr = NetSDS::EDR->new(
		filename => '/mnt/stat/ivr.dat',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	# Create JSON encoder for EDR data processing
	$self->{encoder} = JSON->new();

	# Initialize file to write
	if ( $params{filename} ) {
		$self->{edr_file} = $params{filename};
	} else {
		return $class->error("Required mandatory 'filename' paramter for EDR");
	}

	return $self;

}

#***********************************************************************

=item B<write($rec1 [,$rec2 [...,$recN]])> - write EDR to file

This methods converts records to JSON and write to file.
Each record writing to one separate string.

=cut

#-----------------------------------------------------------------------
sub write {

	my ( $self, @records ) = @_;

	open EDRF, ">>$self->{edr_file}";

	foreach my $rec (@records) {
		my $edr_json = $self->{encoder}->encode($rec);
		print EDRF "$edr_json\n";
	}

	close EDRF;

}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


