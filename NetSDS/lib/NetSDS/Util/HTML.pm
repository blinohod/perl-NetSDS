package NetSDS::Util::HTML;

########################################################################
# Misc HTML routines
#
# $Id$
########################################################################

=head1 NAME

NetSDS::Util::HTML

=head1 SYNOPSIS

	use NetSDS::Util::HTML qw(...);

=head1 DESCRIPTION

Different HTML processing functions.

=cut

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '0.01';

our @EXPORT_OK = qw(
  encode_uri
  decode_uri
  clean_html
  html2text
  decode_html
  encode_html
);

use HTML::SimpleParse;
use HTML::TreeBuilder;
use HTML::FormatText;

use NetSDS::Util::Text qw(
  text_encode
  text_decode
);

my %BADTAG = (
	#	STYLE    => "\n",
	SCRIPT   => "\n",
	APPLET   => "\n",
	OBJECT   => "\n",
	FORM     => "\n",
	INPUT    => "\n",
	TEXTAREA => "\n",
);

#***********************************************************************

=head1 EXPORTS

=over

=item B<encode_uri(...)>

=cut

#-----------------------------------------------------------------------
sub encode_uri {
	my ( $s, $all ) = @_;

	return '' unless defined $s;

	if ($all) {
		$s =~ s/(.)/sprintf("%%%02X", ord($1))/ges;
	} else {
		#	$s =~ s/([^A-Za-z0-9\-_.!~*'()])/sprintf("%%%02X", ord($1))/ge;
		$s =~ s/([^A-Za-z0-9\-_.!~*])/sprintf("%%%02X", ord($1))/ges;
	}

	return $s;
}

#***********************************************************************

=item B<decode_uri(...)>

=cut

#-----------------------------------------------------------------------
sub decode_uri {
	my ($s) = @_;

	return '' unless defined $s;

	$s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

	return $s;
}

#***********************************************************************
sub _parse_tag {
	my ( $htm, $con ) = @_;

	my %arg = ();
	if ( $con =~ /^(?:\/)*([[:alpha:]][:[:alnum:]]*)\s*(.*?)$/s ) {
		$con = $1;
		%arg = $htm->parse_args($2);
	} elsif ( $con =~ /^(?:\/)*([[[:alpha:]][:[:alnum:]]*]+).*?$/ ) {
		$con = $1;
	}

	return wantarray ? ( uc($con), \%arg ) : uc($con);
}

#***********************************************************************

=item B<clean_html(...)>

=cut

#-----------------------------------------------------------------------
sub clean_html {
	my ($buf) = @_;

	return '' unless ($buf);

	my $htm = HTML::SimpleParse->new( $buf, 'fix_case' => 0 );
	my $res = '';
	my $fig = 0;
	foreach my $nod ( $htm->tree ) {
		my $typ = $nod->{type};
		if ( $typ eq 'starttag' ) {
			my $tag = _parse_tag( $htm, $nod->{content} );
			if ( exists $BADTAG{$tag} ) {
				++$fig;
				$res .= $BADTAG{$tag};
			} else {
				$res .= "<" . $nod->{content} . ">";
			}
		} elsif ( $typ eq 'endtag' ) {
			my $tag = _parse_tag( $htm, $nod->{content} );
			if ( exists $BADTAG{$tag} ) {
				--$fig;
				$res .= $BADTAG{$tag};
			} else {
				$res .= "<" . $nod->{content} . ">";
			}
		} elsif ( ( $fig == 0 ) && ( $typ eq 'text' ) ) {
			$res .= $nod->{content};
		}
	} ## end foreach my $nod ( $htm->tree)

	return $res;
} ## end sub clean_html

#***********************************************************************

=item B<html2text(...)>

=cut

#-----------------------------------------------------------------------
sub html2text {
	my ($buf) = @_;

	return '' unless ($buf);

	#	$buf =~ s/&nbsp;/ /gs;

	my $tree = HTML::TreeBuilder->new->parse( text_encode($buf) );
	my $form = HTML::FormatText->new( leftmargin => 0, rightmargin => 99999 );
	return text_decode( $form->format($tree) );
}

#***********************************************************************

=item B<decode_html(...)>

=cut

#-----------------------------------------------------------------------
sub decode_html {
	my $str = shift;

	if ($str) {
		$str =~ s/&lt;/</gs;
		$str =~ s/&gt;/>/gs;
		$str =~ s/&amp;/&/gs;
		$str =~ s/&quot;/"/gs;
	}

	return $str;
}

#***********************************************************************

=item B<encode_html(...)>

Return HTML escaped string:

 * < - &lt;
 * < - &gt;
 * & - &amp;
 * " - &quot;

=cut

#-----------------------------------------------------------------------
sub encode_html {
	my $str = shift;

	unless ($str) {
		$str =~ s/([<>&"])/'&'.($1 eq '&' ? 'amp' : $1 eq '>' ? 'gt' : $1 eq '<' ? 'lt' : 'quot' ).';'/ges;
	}

	return $str;
}

#**************************************************************************
1;
__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

Unknown

=head1 TODO

Document

=head1 SEE ALSO

None

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

=cut
