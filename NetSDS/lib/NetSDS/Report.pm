#===============================================================================
#
#         FILE:  Report.pm
#
#  DESCRIPTION:
#
#        NOTES:  ---
#       AUTHOR:  Andrei Protasovitski (AS_Pushkin), <andrei.protasovitski@gmail.com>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  30.10.2008 13:12:42 EEST
#===============================================================================

=head1 NAME

NetSDS::Report - NetSDS template engine

=head1 SYNOPSIS

	use NetSDS::Report;

=head1 DESCRIPTION

C<NetSDS::Report> class provides developers with ability to create template
based Excel files.

=cut

package NetSDS::Report;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::Class::Abstract);

use Excel::Template;

use NetSDS::Util::File qw/file_read/;

use version; our $VERSION = "1.0";
our @EXPORT_OK = qw();

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])>

Constructor, creates new object, reads all report templates,
create Excel::Template objects anp put them into the hashref.

    my $report = NetSDS::Report->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my %rpt_files = %{ $params{reports} };

	my $rpt = {};
	foreach my $key ( keys %rpt_files ) {

		my $file = $rpt_files{$key};

		my $tem = Excel::Template->new(
									   filename	=> $rpt_files{$key},
									  );
		unless ($tem) {
			return undef;
		}

		$rpt->{$key} = $tem;
	} ## end foreach my $key ( keys %tpl_files)

	return $class->SUPER::new(%{$rpt});

} ## end sub new

#***********************************************************************

=back

=head1 OBJECT METHODS

=over

=item B<render(...)> - returns Excel file

=cut

#-----------------------------------------------------------------------

sub render {

	my ( $this, $name, %params ) = @_;

	my $rpt = $this->{$name};

	unless ($rpt) {
		$this->error( " Wrong template '%s'", $name );
		return undef;
	}

	$rpt->param(%params);

	return $rpt->output;
}

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Andrei Protasovitski <andrei.protasovitski@gmail.com>

=cut


