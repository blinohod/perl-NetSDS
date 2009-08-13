#===============================================================================
#
#         FILE:  Const.pm
#
#  DESCRIPTION:  NetSDS common constants
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  05.05.2008 16:40:51 EEST
#===============================================================================

=head1 NAME

NetSDS::Const - common NetSDS constants

=head1 SYNOPSIS

	use NetSDS::Const;

	print "XML encoding is " . XML_ENCODING;


=head1 DESCRIPTION

This module provides most common constants like default encoding and language, time intervals, etc.

=cut

package NetSDS::Const;

use 5.8.0;
use strict;
use warnings;

use base 'Exporter';

use NetSDS;
use version; our $VERSION = NetSDS->VERSION;

our @EXPORT = qw(
  LANG_BE
  LANG_EN
  LANG_RU
  LANG_UK
  DEFAULT_ENCODING
  DEFAULT_LANG
  XML_VERSION
  XML_ENCODING
  INTERVAL_HOUR
  INTERVAL_DAY
  INTERVAL_WEEK
);

use constant LANG_BE => 'be';
use constant LANG_EN => 'en';
use constant LANG_RU => 'ru';
use constant LANG_UK => 'uk';

use constant DEFAULT_LANG     => LANG_RU;
use constant DEFAULT_ENCODING => 'UTF8';

use constant XML_VERSION  => '1.0';
use constant XML_ENCODING => 'UTF-8';

use constant INTERVAL_HOUR => 3600;
use constant INTERVAL_DAY  => 86400;
use constant INTERVAL_WEEK => 604800;

1;

__END__


=head1 EXAMPLES

None yet

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None yet

=head1 TODO

None yet

=head1 AUTHOR

Valentyn Solomko <val@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


