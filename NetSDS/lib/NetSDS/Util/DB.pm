#===============================================================================
#
#         FILE:  App.pm
#
#  DESCRIPTION:  Common NetSDS applications framework
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  24.04.2008 16:48:24 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::DB - ProstreSQL related routines

=head1 SYNOPSIS

    use NetSDS::Util::DB;

=cut

package NetSDS::Util::DB;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '0.01';

our @EXPORT_OK = qw(
  enquote_pg_array
  enquote_pg_array_ref
  enquote_pg_hash_ref
  dequote_pg_array
  dequote_pg_array_ref
  dequote_pg_hash_ref
);

use POSIX;
use Text::CSV_XS;

our $CSV = undef;

#***********************************************************************

=head1 EXPORTS

=over

=item B<enquote_pg_array()> - encode array to PostgreSQL string

=cut

#-----------------------------------------------------------------------
sub enquote_pg_array {
	unless ($CSV) {
		$CSV = Text::CSV_XS->new( { binary => 1, sep_char => ',', quote_char => '"', escape_char => '\\', always_quote => 1 } );
	}

	if ( $CSV->combine(@_) ) {
		return '{' . $CSV->string . '}';
	} else {
		__PACKAGE__->error( 'Text::CSV_XS->combine: %s', $CSV->error_input );
	}
}

#***********************************************************************

=item B<enquote_pg_array_ref()>

=cut

#-----------------------------------------------------------------------
sub enquote_pg_array_ref {
	if (@_) {
		return enquote_pg_array( @{ $_[0] } );
	} else {
		return '{}';
	}
}

#***********************************************************************

=item B<enquote_pg_hash_ref()>

=cut

#-----------------------------------------------------------------------
sub enquote_pg_hash_ref {
	if (@_) {
		return enquote_pg_array( %{ $_[0] } );
	} else {
		return '{}';
	}
}

#***********************************************************************

=item B<dequote_pg_array()>

=cut

#-----------------------------------------------------------------------
sub dequote_pg_array {
	my ($str) = @_;

	unless ($CSV) {
		$CSV = Text::CSV_XS->new( { binary => 1, sep_char => ',', quote_char => '"', escape_char => '\\', always_quote => 1 } );
	}

	$str =~ s/^{(.*)}$/$1/;
	if ( $CSV->parse($str) ) {
		return $CSV->fields;
	} else {
		__PACKAGE__->error( 'Text::CSV_XS->parse: %s', $CSV->error_input );
	}
}

#***********************************************************************

=item B<dequote_pg_array_ref()>

Dequote PostgreSQL array to array reference

=cut

#-----------------------------------------------------------------------
sub dequote_pg_array_ref {
	return [ dequote_pg_array(@_) ];
}

#***********************************************************************

=item B<dequote_pg_hash_ref()>

Dequote PostgreSQL array to hash reference

=cut

#-----------------------------------------------------------------------
sub dequote_pg_hash_ref {
	return { dequote_pg_array(@_) };
}

#***********************************************************************
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

PostgreSQL documentation

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

=cut
