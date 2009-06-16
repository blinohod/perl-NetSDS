#===============================================================================
#
#         FILE:  Text.pm
#
#  DESCRIPTION:  Utilities for easy text processing
#
#         NOTE:  This module ported from Wono framework "as is"
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  03.08.2008 15:04:22 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::Text - text prcessing routines

=head1 SYNOPSIS

	use NetSDS::Util::Text qw(text_encode text_decode);

	# Read from standard input
	my $string = <STDIN>;

	# Encode string to internal structure
	$string = text_encode($tring);


=head1 DESCRIPTION

C<NetSDS::Util::Text> module contains functions may be used to quickly solve
string processing tasks like parsing, recoding, formatting.

As in other NetSDS modules standard encoding is UTF-8.

=cut

package NetSDS::Util::Text;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '0.01';

our @EXPORT_OK = qw(
  text_encode
  text_decode
  text_recode
  text_clean
  string_clean
  trimb
  triml
  trimr
  cyr2lat
  lat2cyr
  camelize
  decamelize
  text2parse
  parse2text
  parse2words
);

use POSIX;
use Encode qw(
  encode
  decode
  encode_utf8
  decode_utf8
  from_to
  is_utf8
);

use NetSDS::Const;

my $BLANK = "[:blank:][:space:][:cntrl:]";

my %PREP = (
	LANG_RU() => {
		'а'  => 'a',
		'б'  => 'b',
		'в'  => 'v',
		'г'  => 'g',
		'д'  => 'd',
		'е'  => 'e',
		'ё'  => 'yo',
		'ж'  => 'zh',
		'з'  => 'z',
		'и'  => 'i',
		'й'  => 'j',
		'к'  => 'k',
		'л'  => 'l',
		'м'  => 'm',
		'н'  => 'n',
		'о'  => 'o',
		'п'  => 'p',
		'р'  => 'r',
		'с'  => 's',
		'т'  => 't',
		'у'  => 'u',
		'ф'  => 'f',
		'х'  => 'kh',
		'ц'  => 'tc',
		'ч'  => 'ch',
		'ш'  => 'sh',
		'щ'  => 'sch',
		'ъ'  => '"',
		'ы'  => 'y',
		'ые' => 'yje',
		'ыё' => 'yjo',
		'ыу' => 'yiu',
		'ыю' => 'yju',
		'ыя' => 'yja',
		'ь'  => "'",
		'ье' => 'jie',
		'ьё' => 'jio',
		'ью' => 'jiu',
		'ья' => 'jia',
		'э'  => 'ye',
		'ю'  => 'yu',
		'я'  => 'ya',
	},

	LANG_UK() => {
		"'" => '"',
		'а' => 'a',
		'б' => 'b',
		'в' => 'v',
		'ґ' => 'g',
		'г' => 'h',
		'д' => 'd',
		'е' => 'e',
		'є' => 'ye',
		'ж' => 'zh',
		'з' => 'z',
		'і' => 'i',
		'и' => 'y',
		'ї' => 'yi',
		'й' => 'j',
		'к' => 'k',
		'л' => 'l',
		'м' => 'm',
		'н' => 'n',
		'о' => 'o',
		'п' => 'p',
		'р' => 'r',
		'с' => 's',
		'т' => 't',
		'у' => 'u',
		'ф' => 'f',
		'х' => 'kh',
		'ц' => 'tc',
		'ч' => 'ch',
		'ш' => 'sh',
		'щ' => 'sch',
		'ь' => "'",
		'ю' => 'yu',
		'я' => 'ya',
	},

	LANG_BE() => {
		"'"  => '"',
		'а'  => 'a',
		'б'  => 'b',
		'в'  => 'v',
		'ґ'  => 'g',
		'г'  => 'h',
		'д'  => 'd',
		'е'  => 'ye',
		'ё'  => 'yo',
		'ж'  => 'zh',
		'з'  => 'z',
		'і'  => 'i',
		'и'  => 'i',
		'ї'  => 'yi',
		'й'  => 'j',
		'к'  => 'k',
		'л'  => 'l',
		'м'  => 'm',
		'н'  => 'n',
		'о'  => 'o',
		'п'  => 'p',
		'р'  => 'r',
		'с'  => 's',
		'т'  => 't',
		'у'  => 'u',
		'ў'  => 'w',
		'ф'  => 'f',
		'х'  => 'kh',
		'ц'  => 'tc',
		'ч'  => 'ch',
		'ш'  => 'sh',
		'щ'  => 'sch',
		'ы'  => 'y',
		'ые' => 'yje',
		'ыё' => 'yjo',
		'ыу' => 'yiu',
		'ыю' => 'yju',
		'ыя' => 'yja',
		'ь'  => "'",
		'ье' => 'jie',
		'ьё' => 'jio',
		'ью' => 'jiu',
		'ья' => 'jia',
		'э'  => 'e',
		'ю'  => 'yu',
		'я'  => 'ya',
	},
);

my %TO_LAT = ();

my %TO_CYR = ();

#***********************************************************************

=head1 EXPORTS

=over

=item B<text_encode(TEXT[, $encoding])>

Encode given text string to internal encoding.

If external encoding isn't UTF-8, it should be given as second parameter.

=cut

#-----------------------------------------------------------------------
sub text_encode {
	my ( $txt, $enc ) = @_;

	if ( defined($txt) and ( $txt ne '' ) ) {
		unless ( is_utf8($txt) ) {
			$txt = decode( $enc || DEFAULT_ENCODING, $txt );
		}
	}

	return $txt;
}

#***********************************************************************

=item B<text_decode(TEXT[, $encoding])>

Decode text from internal encoding to external string.

If external encoding isn't UTF-8, it should be given as second parameter.

=cut

#-----------------------------------------------------------------------
sub text_decode {
	my ( $txt, $enc ) = @_;

	if ( defined($txt) and ( $txt ne '' ) ) {
		if ( is_utf8($txt) ) {
			$txt = encode( $enc || DEFAULT_ENCODING, $txt );
		}
	}

	return $txt;
}

#***********************************************************************

=item B<text_recode($TEXT, $FROM_ENC[, $TO_ENC])>

Recode string from one encoding to another (UTF-8 is default target).

=cut

#-----------------------------------------------------------------------
sub text_recode {
	my ( $txt, $enc, $trg ) = @_;

	if ( defined($txt) and ( $txt ne '' ) ) {
		if ($enc) {
			my $len = from_to( $txt, $enc, $trg || DEFAULT_ENCODING );
			unless ( defined($len) ) {
				$txt = undef;
			}
		}
	}

	return $txt;
}

#***********************************************************************

=item B<text_clean(TEXT)>

Cleaning string from leading and trailing space characters.
Also space chains are changing with single spaces.

=cut

#-----------------------------------------------------------------------
sub text_clean {
	my ($txt) = @_;

	if ( defined($txt) and ( $txt ne '' ) ) {
		$txt =~ s/^[$BLANK]+//s;
		$txt =~ s/[$BLANK]+$//s;
		$txt =~ s/[$BLANK]+/ /gs;
	}

	return $txt;
}

#***********************************************************************

=item B<string_clean(STRING[, LENGTH][, DEFAULT])>

Clean string from leading and trailing space characters. 
Also space chains are changing with single spaces.

Then string is trimmed to given length.

If original string is empty or undefined then default value returns.

=cut

#-----------------------------------------------------------------------
sub string_clean {
	my ( $s, $l, $d ) = @_;

	if ( defined($s) ) {
		$s =~ s/[$BLANK]+/ /gs;
		$s =~ s/^[$BLANK]+//s;
		$s =~ s/[$BLANK]+$//s;
		if ( $s ne '' ) {
			return ($l) ? substr( $s, 0, $l ) : $s;
		} else {
			return defined($d) ? $d : '';
		}
	} else {
		return $d;
	}
}

#***********************************************************************

=item B<trimb($str)>

Removes leading and trailing whitespace from argument.

=cut

#-----------------------------------------------------------------------
sub trimb {
	my ($s) = @_;

	if ( defined($s) and ( $s ne '' ) ) {
		$s =~ s/^[$BLANK]+//s;
		$s =~ s/[$BLANK]+$//s;
	}

	return $s;
}

#***********************************************************************

=item B<triml($str)>

Like trimb() but removes only leading (left) whitespaces.

=cut

#-----------------------------------------------------------------------
sub triml {
	my ($s) = @_ ? @_ : $_;

	if ( defined($s) and ( $s ne '' ) ) {
		$s =~ s/^[$BLANK]+//s;
	}

	return $s;
}

#***********************************************************************

=item B<trimr(...)>

Like trim() but removes only trailing (right) whitespace.

=cut

#-----------------------------------------------------------------------
sub trimr {
	my ($s) = @_ ? @_ : $_;

	if ( defined($s) and ( $s ne '' ) ) {
		$s =~ s/[$BLANK]+$//s;
	}

	return $s;
}

#*********************************************************************************************
sub _prep_translit {
	my ($lang) = @_;

	return if ( $PREP{prepared}->{$lang} );

	my $rfw = {};
	my $rbw = {};
	while ( my ( $fw, $bw ) = each %{ $PREP{$lang} } ) {
		$fw = text_encode($fw);
		$bw = text_encode($bw);
		my $lf = length($fw);
		my $lb = length($bw);
		if ( ( $lf == 1 ) and ( $lb == 1 ) ) {
			$rfw->{0}->{ uc($fw) }      = uc($bw);
			$rfw->{0}->{ ucfirst($fw) } = ucfirst($bw);
			$rfw->{0}->{$fw}            = $bw;

			$rbw->{0}->{ uc($bw) }      = uc($fw);
			$rbw->{0}->{ ucfirst($bw) } = ucfirst($fw);
			$rbw->{0}->{$bw}            = $fw;
		} else {
			$rfw->{$lf}->{ uc($fw) }      = uc($bw);
			$rfw->{$lf}->{ ucfirst($fw) } = ucfirst($bw);
			$rfw->{$lf}->{$fw}            = $bw;

			$rbw->{$lb}->{ uc($bw) }      = uc($fw);
			$rbw->{$lb}->{ ucfirst($bw) } = ucfirst($fw);
			$rbw->{$lb}->{$bw}            = $fw;
		}
	} ## end while ( my ( $fw, $bw ) =...

	$TO_LAT{$lang} = [];
	foreach my $ord ( reverse sort { $a <=> $b } keys %{$rfw} ) {
		my $tra = $rfw->{$ord};
		my $fnd = join( '|', keys %{$tra} );
		push( @{ $TO_LAT{$lang} }, [ $fnd, $tra ] );
	}

	$TO_CYR{$lang} = [];
	foreach my $ord ( reverse sort { $a <=> $b } keys %{$rbw} ) {
		my $tra = $rbw->{$ord};
		my $fnd = join( '|', keys %{$tra} );
		push( @{ $TO_CYR{$lang} }, [ $fnd, $tra ] );
	}

	$PREP{prepared}->{$lang} = 1;
} ## end sub _prep_translit

#*********************************************************************************************

=item B<cyr2lat($text[, $lang])>

Transliterate text from cyrillic to latin encoding.

Text language may be set if not default one.

	$lat = cyr2lat($string);

=cut

#-----------------------------------------------------------------------
sub cyr2lat {
	my ( $text, $lang ) = @_;

	$lang ||= DEFAULT_LANG();

	_prep_translit($lang);

	$text = text_encode($text);

	foreach my $row ( @{ $TO_LAT{$lang} } ) {
		my ( $fnd, $has ) = @{$row};
		$text =~ s/($row->[0])/$row->[1]->{$1}/ge;
	}
	$text =~ s/[^\x{0}-\x{7f}]+/\?/g;

	return text_decode($text);
}

#*********************************************************************************************

=item B<lat2cyr($text[, $lang])>

Transliterate string from latin encoding to cyrillic one.

Text language may be set if not default one.

	$cyr = lat2cyr("Sam baran", "ru");

=cut

#-----------------------------------------------------------------------
sub lat2cyr {
	my ( $text, $lang ) = @_;

	$lang ||= DEFAULT_LANG();

	_prep_translit($lang);

	$text = text_encode($text);

	$text =~ s/[^\x{0}-\x{7f}]+/\?/g;
	foreach my $row ( @{ $TO_CYR{$lang} } ) {
		my ( $fnd, $has ) = @{$row};
		$text =~ s/($row->[0])/$row->[1]->{$1}/sg;
	}

	return text_decode($text);
}

#**************************************************************************

=item B<camelize($strin)>

 If pass undef - return undef.
 If pass '' - return ''.

 Examples:
	camelize( 'get_value' )
		returns 'getValue'

	camelize( 'ADD_User_actION' )
		returns 'addUserAction'

=cut

#-----------------------------------------------------------------------
sub camelize {
	my $s = shift;

	if ( defined($s) and ( $s ne '' ) ) {
		$s = lc($s);
		$s =~ s/_([0-9a-z])/\U$1/g;
	}

	return $s;
}

#**************************************************************************

=item B<decamelize(...)>

 If pass undef - return undef.
 If pass '' - return ''.

 Examples:
	decamelize( 'getValue' )
		returns 'get_value'

=cut

#-----------------------------------------------------------------------
sub decamelize {
	my $s = shift;

	$s =~ s/([A-Z])/_\L$1/g;

	return lc($s);
}

#***********************************************************************

=item B<text2parse($text[, \@parsed])>

Convert text to internal structure (array reference).

Parameters:

	* text to parse

	* (optional) start structure

Example:

	my @words = ('one','two');

	my $res = text2parse("three four", \@words);

Return is ['one','two','there','four'];

=cut

#-----------------------------------------------------------------------
sub text2parse {
	my ( $txt, $res ) = @_;
	$res ||= [];

	push( @{$res}, split( m/[$BLANK]+/s, $txt ) );

	return $res;
}

#***********************************************************************

=item B<parse2text(\@PARSED[, $TEXT][, $MIN][, $MAX])>

Convert parsed structure (array reference) to scalar string.

=cut

#-----------------------------------------------------------------------
sub parse2text {
	my ( $prs, $txt, $min, $max ) = @_;

	$min ||= 0;
	$max ||= $#{$prs};
	$txt ||= '';

	$txt .= join( ' ', @{$prs}[ $min .. $max ] );

	return $txt;
}

#***********************************************************************

=item B<parse2words(\@PARSED[, \@WORDS])>

Select from parsed structure words list.

=cut

#-----------------------------------------------------------------------
sub parse2words {
	my ( $prs, $wds ) = @_;
	$wds ||= [];

	my $s;
	foreach my $wd ( @{$prs} ) {
		if ( ( $wd ne '' ) and ( $wd =~ /[[:alnum:]]/ ) ) {

			($s) = $wd =~ m/^(?:[^[:alnum:]]*)(.+?)(?:[^[:alnum:]]*)$/;

			push( @{$wds}, $s );
		}
	}

	return $wds;
}

#**************************************************************************
1;
__END__

=back

=head1 EXAMPLES

None yet

=head1 BUGS

Unknown yet

=head1 TODO

Implement examples and tests.

=head1 SEE ALSO

L<Encode>, L<perlunicode>

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

=cut
