#===============================================================================
#
#         FILE:  Misc.pm
#
#  DESCRIPTION:
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  17.08.2008 17:01:48 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::Misc - miscelaneous utilities

=head1 SYNOPSIS

	use NetSDS::Util::Misc qw(...);

=head1 DESCRIPTION

C<NetSDS::Util::Misc> module contains miscelaneous functions.

=over

=item * CLI parameters processing

=item * types validation

=item * HEX, Base64, URI, BCD encondig

=item * UUID processing

=back

=cut

package NetSDS::Util::Misc;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '0.10';

our @EXPORT_OK = qw(
  cmp_version
  usage
  get_cli
  is_int
  is_float
  is_date
  is_binary
  str2hex
  chr2hex
  hex2str
  hex2chr
  str2bcd
  make_uuid
  str2base64
  base642str
  str2uri
  uri2str
  csv_num
);

use POSIX;
use Getopt::Long;
use Pod::Usage;
use Data::Structure::Util qw(
  has_utf8
);
use Data::UUID;
use MIME::Base64;
use URI::Escape;

#***********************************************************************

=head1 EXPORTED FUNCTIONS

=over

=item B<cmp_version($ver1, $ver2)> - compare versions

Funcion comapres two version strings.

=cut

#-----------------------------------------------------------------------
sub cmp_version {
	my ( $ver1, $ver2 ) = @_;

	return sprintf( "%03d.%03d", split( m/\./, $ver1 ) ) cmp sprintf( "%03d.%03d", split( m/\./, $ver2 ) );
}

#***********************************************************************

=item B<usage(...)> - print C<usage> text

This function is wapper to L<Pod::Usage> module

=cut

#-----------------------------------------------------------------------
sub usage {
	pod2usage(
		-message => sprintf( shift(@_), @_ ),
		-verbose => 0,
		-exitval => 2,
		-output  => \*STDERR
	);
}

#***********************************************************************

=item B<get_cli(...)> - get CLI parameters

Return command line arguments

=cut

#-----------------------------------------------------------------------
sub get_cli {
	my ( $res, @opa ) = @_;

	my $ret  = undef;
	my @argv = @ARGV;    # save @ARGV
	{
		# Switch off warnings because of other CLI parameters
		# still not known
		my $warn = $SIG{__WARN__};
		$SIG{__WARN__} = sub { };
		$ret = GetOptions( $res, @opa, 'help|h|?', 'man|m' );
		$SIG{__WARN__} = $warn;
	}
	@ARGV = @argv;       # restore @ARGV

	# GetOptions bug workaround
	#	if ( !$ret ) {
	#		pod2usage( -verbose => 0, -exitval => 2, -output => \*STDERR );
	#	} elsif ( exists( $res->{help} ) and $res->{help} ) {
	if ( exists( $res->{help} ) and $res->{help} ) {
		pod2usage( -verbose => 1, -exitval => 2, -output => \*STDERR );
	} elsif ( exists( $res->{man} ) and $res->{man} ) {
		pod2usage( -verbose => 2, -exitval => 2, -output => \*STDERR );
	}

	return $res;
} ## end sub get_cli

#***********************************************************************

=item B<is_int([...])> - check if parameter is integer

Check if given parameter is integer

=cut

#-----------------------------------------------------------------------
sub is_int {
	my ($value) = @_;

	return 0 unless defined $value;

	return ( ( $value =~ /^[-+]?\d+$/ ) and ( $value >= INT_MIN ) and ( $value <= INT_MAX ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_float([...])> - check if parameter is float number

Check if given parameter is float number

=cut

#-----------------------------------------------------------------------
sub is_float {
	my ($value) = @_;

	return 0 unless defined $value;

	#	return ( ( $value =~ m/^[-+]?(?=\d|\.\d)\d*(\.\d*)?([Ee]([-+]?\d+))?$/ ) and ( ( $value >= 0 ) and ( $value >= DBL_MIN() ) and ( $value <= DBL_MAX() ) ) or ( ( $value < 0 ) and ( $value >= -DBL_MAX() ) and ( $value <= -DBL_MIN() ) ) ) ? 1 : 0;
	return ( $value =~ m/^[-+]?(?=\d|\.\d)\d*(\.\d*)?([Ee]([-+]?\d+))?$/ ) ? 1 : 0;
}

#***********************************************************************

=item B<is_date([...])> - check if parameter is date string

Return 1 if parameter is date string

=cut

#-----------------------------------------------------------------------
sub is_date {
	my ($value) = @_;

	return 0 unless defined $value;

	return ( $value =~ m/^\d{8}T\d{2}:\d{2}:\d{2}(Z|[-+]\d{1,2}(?::\d{2})*)$/ ) ? 1 : 0;
}

#***********************************************************************

=item B<is_binary([...])> - check for binary content

Return 1 if parameter is non text.

=cut

#-----------------------------------------------------------------------
sub is_binary {
	my ($value) = @_;

	if ( has_utf8($value) ) {
		return 0;
	} else {
		return ( $value =~ m/[^\x09\x0a\x0d\x20-\x7f[:print:]]/ ) ? 1 : 0;
	}
}

#***********************************************************************

=item B<str2hex($str)> - encode to hex

Hex encoding for string

Example:

	print "Hex from string " . hex2str('Want hex dump!');

=cut

#-----------------------------------------------------------------------
sub str2hex {
	my ($str) = @_;

	return defined($str) ? uc( unpack( "H*", "$str" ) ) : "";
}

#***********************************************************************

=item B<hex2str($string)> - decode hex string

Hex decoding for string.

Example:

	print "String from hex: " . hex2str('7A686F7061');

=cut

#-----------------------------------------------------------------------
sub hex2str {
	my ($hex) = @_;

	return defined($hex) ? pack( "H*", "$hex" ) : ""; #"$hex";
}

#***********************************************************************

=item B<chr2hex($char)> - encode char to hex

Hex encoding for char

=cut

#-----------------------------------------------------------------------
sub chr2hex {
	my ($chr) = @_;

	return defined($chr) ? uc( unpack( "H2", "$chr" ) ) : "$chr";
}

#***********************************************************************

=item B<hex2chr($hex)> - decode char from hex

Hex decoding for char

=cut

#-----------------------------------------------------------------------
sub hex2chr {
	my ($hex) = @_;

	return defined($hex) ? pack( "H2", "$hex" ) : "$hex";
}

#***********************************************************************

=item B<str2bcd(...)> - little-endian BCD encoding

Convert string to little-endian BCD, filled with F16

=cut

#-----------------------------------------------------------------------
sub str2bcd {
	my ($str) = @_;

	$str = "$str" . 'F' x ( length("$str") % 2 );
	$str =~ s/([\dF])([\dF])/$2$1/g;
	return hex2str($str);
}

#***********************************************************************

=item B<make_uuid()> - make UUD string

Create upper case UUID string.

=cut

#-----------------------------------------------------------------------
sub make_uuid {

	return Data::UUID->new()->create_str();

}

#***********************************************************************

=item B<str2base64($str)> - convert string to Base64 

Example: 

	my $b64 = str2base64("Hallo, people!");

=cut 

#-----------------------------------------------------------------------

sub str2base64 {

	my ($str) = @_;

	return encode_base64($str);

}

#***********************************************************************

=item B<base642str($b64)> - decode Base64 string

Example: 

	my $str = base642str($base64_string);

=cut 

#-----------------------------------------------------------------------

sub base642str {

	my ($str) = @_;

	return decode_base64($str);

}

#***********************************************************************

=item B<str2uri($str)> - convert string to URI encoded 

Example: 

	my $uri = str2uri("http://www.google.com/?q=what");

=cut 

#-----------------------------------------------------------------------

sub str2uri {

	my ($str) = @_;

	return uri_escape($str, "\x00-\xff");

}

#***********************************************************************

=item B<uri2str($uri)> - decode URI encoded string

Example: 

	my $str = uri2str($uri_string);

=cut 

#-----------------------------------------------------------------------

sub uri2str {

	my ($str) = @_;

	return uri_unescape($str);

}


#***********************************************************************

=item B<csv_num($num)> - format number for CSV 

Paramters: numeric value

Returns: CSV formatted

=cut 

sub csv_num {

	my ($num) = @_;
	$num =~ s/\./,/g;
	$num = "\"$num\"";

	return $num;
}

#-----------------------------------------------------------------------

#**************************************************************************
1;
__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

None

=head1 TODO

1. Add other encodings support

=head1 SEE ALSO

L<Pod::Usage>, L<Data::UUID>

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
