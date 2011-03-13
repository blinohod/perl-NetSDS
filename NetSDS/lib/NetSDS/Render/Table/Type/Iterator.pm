package NetSDS::Render::Table::Type::Iterator;

use version;
use warnings;
use strict;
our $VERSION = '1.0000';

sub new {
	my ( $class, $dataset ) = @_;
	my $has_needed = 1;
	foreach my $key qw(value is_exhausted isnt_exhausted) {
		if ( !$dataset->can($key) ) {
			$has_needed = 0;
		}
	}
	if ( !$has_needed ) {
		return undef;
	}
	return $dataset;
}

1;
