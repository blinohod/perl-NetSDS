=head1 NAME

NetSDS::Util::Aggregator - an object to reorganize flat arrays into hierarchies.

=head1 SYNOPSIS

	#!/usr/bin/env perl

	use 5.8.0;
	use warnings;
	use strict;

	use Iterator::Util qw(iarray);
	use NetSDS::Util::Aggregator;
	use Data::Dumper;

	my $aggregator = NetSDS::Util::Aggregator->new(
		iarray([
		{id => 1, name => 'Ivan', 'surname' => 'Petroff', 'group' => 'administrators', 'membership' => 'fulltime'},
		{id => 1, name => 'Ivan', 'surname' => 'Petroff', 'group' => 'salesmen', 'membership' => 'fulltime'},
		{id => 1, name => 'Ivan', 'surname' => 'Petroff', 'group' => 'cleaners', 'membership' => 'halftime'},
		]), 'id', ['id', 'name', 'surname'], {groups => ['group', 'membership']}
	);

	my $res = $aggregator->iter();
	
	while(!$res->is_exhausted) {
		print Dumper($res->value);
	}

	1;
	
Output:

$VAR1 = {
          'groups' => [
                        {
                          'group' => 'administrators',
                          'membership' => 'fulltime'
                        },
                        {
                          'group' => 'salesmen',
                          'membership' => 'fulltime'
                        }
                      ],
          'name' => 'Ivan',
          'id' => 1,
          'surname' => 'Petroff'
        };

=head1 DESCRIPTION

C<NetSDS::Util::Aggregator> module lets a flat structure (like that fetchable from a RDBMS)
to be reorganized in a hierarchical fashion.

=cut
package NetSDS::Util::Aggregator;

use version; our $VERSION = 1.000;

use Iterator;

sub new {
	my ( $class, $source, $keyfield, $static, $aggregated ) = @_;
	my $self = {
		source     => $source,
		static     => $static,
		aggregated => $aggregated,
		current    => undef,
		keyfield   => $keyfield,
	};
	bless $self, $class;
	return $self;
}

sub iter {
	my $self = shift;
	return Iterator->new(
		sub {
			if ( $self->{source}->is_exhausted ) {
				Iterator::is_done;
			}
			my $currec;
			if ( !$self->{current} ) {
				$self->{current} = $self->{source}->value();
			}
			$currec = $self->{current};
			my $tmp_rec = {};
			do {
				$self->{current} = $currec;
				foreach my $key ( @{ $self->{static} } ) {
					$tmp_rec->{$key} = $currec->{$key};
				}
				foreach my $akey ( keys %{ $self->{aggregated} } ) {
					$tmp_rec->{$akey} = [] if !$tmp_rec->{$akey};
					my $tmp_row = {};
					foreach my $vkey ( @{ $self->{aggregated}->{$akey} } ) {
						$tmp_row->{$vkey} = $currec->{$vkey};
					}
					push @{ $tmp_rec->{$akey} }, $tmp_row;
				}
				$currec = $self->{source}->value();
			} while ( ( !$self->{source}->is_exhausted() ) && ( $currec->{ $self->{keyfield} } eq $self->{current}->{ $self->{keyfield} } ) );
			$self->{current} = $currec;
			return $tmp_rec;
		}
	);
} ## end sub iter

1;
