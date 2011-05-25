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
