package NetSDS::Render::Table::Type::Array;

use version;
use warnings;
use strict;
use Iterator::Util qw (ilist iarray);
our $VERSION = '1.0000';

sub new {
	my ($class, $dataset) = @_;
	if (ref($dataset) eq 'ARRAY') {
		my $value = iarray ($dataset);
		return $value;
	}
	return undef;
}


1;