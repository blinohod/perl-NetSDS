package NetSDS::Render::Table::Type::NDBI;

use version;
use warnings;
use strict;
use Iterator;
our $VERSION = '1.0000';

sub new {
	my ( $class, $dataset ) = @_;
	if ( $dataset->can('fetchrow_hashref') ) {
		return Iterator->new(
			sub {
				if   ( my $row = $dataset->fetchrow_hashref() ) { return $row; }
				else                                            { return Iterator::is_done(); }
			}
		);
	}
	return undef;
}

1;
