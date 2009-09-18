#===============================================================================
#
#         FILE:  Translate.pm
#
#  DESCRIPTION:  Gettext wrapper
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  03.08.2009 13:34:51 UTC
#===============================================================================

=head1 NAME

NetSDS::Translate - simple API to gettext

=head1 SYNOPSIS

	use NetSDS::Translate;

	my $trans = NetSDS::Translate->new(
		lang => 'ru',
		domain => 'NetSDS-IVR',
	);

	print $trans->translate("Detect CallerID");

=head1 DESCRIPTION

C<NetSDS::Translate> module provides API to gettext translation subsystem

=cut

package NetSDS::Translate;

use 5.8.0;
use strict;
use warnings;

use POSIX;
use Locale::gettext;
use NetSDS::Const;

use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = '1.205';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

    my $trans = NetSDS::Translate->new(
		lang => 'ru',
		domain => 'NetSDS-IVR',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# FIXME - this should be configurable option
	my %locale = (
		ru => 'ru_RU.UTF-8',
		en => 'en_US.UTF-8',
		ua => 'ua_UK.UTF-8',
	);

	my $this = $class->SUPER::new(
		lang   => DEFAULT_LANG,
		domain => 'NetSDS',
		%params,
	);

	setlocale( LC_MESSAGES, $locale{$this->{lang}} );
	$this->{translator} = Locale::gettext->domain($this->{domain});

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<translate($string)> - translate string

Return translated string.

	print $trans->translate("All ok");

=cut

#-----------------------------------------------------------------------

sub translate {

	my ( $this, $str ) = @_;

	return $this->{translator}->get($str);

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

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


