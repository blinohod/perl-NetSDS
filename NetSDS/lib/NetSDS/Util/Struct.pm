package NetSDS::Util::Struct;
########################################################################
# Misc Struct routines
#
# $Id$
########################################################################

=head1 NAME

NetSDS::Util::Struct - data structure convertors and checkers

=head1 SYNOPSIS

	use NetSDS::Util::Struct qw(dump2row is_ref_array);

	...

	my $str = dump2row($some_structure);


=head1 DESCRIPTION

NetSDS::Util::Struct module contains different utilities for data structures processing.

=cut

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = "0.2";

our @EXPORT_OK = qw(
  is_ref_scalar
  is_ref_array
  is_ref_hash
  is_ref_code
  is_ref_obj
  dump2string
  dump2row
  arrays2hash
  to_array
  merge_hash
);

use Scalar::Util qw(
  blessed
  reftype
);

use NetSDS::Const;

#***********************************************************************

=head1 EXPORTED METHODS

=over

=item B<is_ref_scalar($ref)> - scheck if reference to scalar value

Return true if parameter is a scalar reference.

	my $var = 'Scalar string';
	if (is_ref_scalar(\$var)) {
		print "It's scalar value";
	}

=cut

#-----------------------------------------------------------------------
sub is_ref_scalar {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'SCALAR' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_array($ref)>

Return true if parameter is an array reference.

=cut

#-----------------------------------------------------------------------
sub is_ref_array {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'ARRAY' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_hash($ref)>

Return true if parameter is a hash reference.

=cut

#-----------------------------------------------------------------------
sub is_ref_hash {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'HASH' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_code($ref)>

Return true if parameter is a code reference.

=cut

#-----------------------------------------------------------------------
sub is_ref_code {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'CODE' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_obj($ref, [$class_name])>

Return true if parameter is an object.

=cut

#-----------------------------------------------------------------------
sub is_ref_obj {
	return blessed( $_[0] ) ? 1 : 0;
}

#***********************************************************************

=item B<dump2string(...)>

Returns cleaned dump to scalar.

=cut

#-----------------------------------------------------------------------
sub dump2string {
	my $dmp = Data::Dumper->new( ( scalar(@_) > 1 ) ? [ \@_ ] : \@_, ['DUMP'] );
	$dmp->Terse(0);
	$dmp->Deepcopy(0);
	$dmp->Sortkeys(1);
	$dmp->Quotekeys(0);
	$dmp->Indent(1);
	$dmp->Pair(': ');
	$dmp->Bless('obj');
	return $dmp->Dump();
}

#***********************************************************************

=item B<dump2row(...)>

Returns cleaned dump to scalar.

=cut

#-----------------------------------------------------------------------
sub dump2row {

	my $str = dump2string(@_);

	if ( $str =~ s/^\s*\$DUMP\s+=\s+[{\[]\s+//s ) {
		$str =~ s/\s+[}\]];\s+$//s;
	} else {
		$str =~ s/^\s*\$DUMP\s+=\s+//s;
		$str =~ s/\s;\s+$//s;
	}
	$str =~ s/\$DUMP/\$/g;
	$str =~ s/\s+/ /g;
	$str =~ s/\\'/'/g;
	$str =~ s/\\undef/undef/g;
	$str =~ s/\\(\d)/$1/g;

	return $str;
}

#***********************************************************************

=item B<to_array($data)>

=cut

#-----------------------------------------------------------------------
sub to_array {
	my ($data) = @_;

	if ( is_ref_array($data) ) {
		return $data;
	} elsif ( is_ref_hash($data) ) {
		return [ keys %{$data} ];
	} elsif ( defined($data) ) {
		return [$data];
	} else {
		return $data;
	}
}

#***********************************************************************

=item B<arrays2hash($keys_ref, $values_ref)> - translate arrays to hash

Parameters: references to keys array and values array

Return: hash

If @$keys_ref is longer than @$values_ref - rest of keys filled with
C<undef> values.

If @$keys_ref is shorter than @$values_ref - rest of values are discarded.

If any of parameters isn't array reference then C<undef> will return.

Example:

	my %h = array2hash(['fruit','animal'], ['apple','horse']);

Result should be a hash:

	(
		fruit => 'apple',
		animal => 'horse'
	)

=cut

#-----------------------------------------------------------------------
sub arrays2hash {
	my ( $keys_ref, $values_ref ) = @_;

	return undef unless ( is_ref_array($keys_ref) and is_ref_array($values_ref) );

	my %h = ();

	for ( my $i = 0 ; $i < scalar(@$keys_ref) ; $i++ ) {
		$h{ $keys_ref->[$i] } = defined( $values_ref->[$i] ) ? $values_ref->[$i] : undef;
	}

	return %h;
}

#***********************************************************************

=item B<merge_hash($target, $source)> - merge two hashes

Parameters: references to target and source hashes.

This method adds source hash to target one and return value as a result.

=cut

#-----------------------------------------------------------------------
sub merge_hash {
	my ( $trg, $src ) = @_;

	while ( my ( $key, $val ) = each( %{$src} ) ) {
		if ( is_ref_hash($val) and is_ref_hash( $trg->{$key} ) ) {
			merge_hash( $trg->{$key}, $val );
		} else {
			$trg->{$key} = $val;
		}
	}

	return $trg;
}

#**************************************************************************
1;
__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

Unknown yet

=head1 TODO

None

=head1 SEE ALSO

None

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

=cut
