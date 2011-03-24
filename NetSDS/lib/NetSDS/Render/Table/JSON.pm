package NetSDS::Render::Table::JSON;

=pod

=head1 NAME

NetSDS::Render::Table::JSON — mixin to render table data as a JSON structure

=cut

use mro 'c3';
use base qw(NetSDS::Render::Table);
use JSON;

sub json_format_table_start {
	return '{';
}

sub json_format_table_end {
	return '}';
}

sub json_format_table_header {
	my  $self = shift;
	return '"columns" : '.$self->{_JSON}->encode($self->columns_order()).", ";
}

sub json_body_start {
	my  $self = shift;
	return '"data" : [';
}

sub json_body_end {
	my  $self = shift;
	return ']';
}

sub value {
	my $self = shift;
	if (!defined($self->{_JSON})) {
		$self->{_JSON} = JSON->new();
	}
	if ( !defined( $self->{__render_state} ) ) {
		$self->{__render_state} = 'head';
		return $self->json_format_table_start();
	} elsif ( $self->{__render_state} eq 'head' ) {
		$self->{__render_state} = 'body_start';
		return $self->json_format_table_header();
	} elsif ( $self->{__render_state} eq 'body_start' ) {
		$self->{__render_state} = 'body';
		return $self->json_body_start();
	} elsif ( $self->{__render_state} eq 'body' ) {
		if ( $self->dataset->isnt_exhausted ) {
			my $row = $self->dataset->value();
			return $self->json_format_table_body_row($row).($self->dataset->isnt_exhausted ? ", " : "");
		} else {
			$self->{__render_state} = 'foot';
			return $self->json_body_end();
		}
	} elsif ( $self->{__render_state} eq 'foot' ) {
		$self->{__render_state} = 'exhausted';
		return $self->json_format_table_end();
	}
} ## end sub value

sub json_format_table_body_row {
	my ( $self, $row ) = @_;
	my $cells = $self->json_get_table_row_cells($row);
	return $self->{_JSON}->encode($cells);
}

sub json_get_table_row_cells {
	my ( $self, $row ) = @_;
	my @cells = ();
	foreach my $cell ( @{ $self->columns_order } ) {
		push @cells, $self->json_format_table_body_cell( $row, $cell );
	}
	return \@cells;
}

sub json_format_table_body_cell {
	my ( $self, $row, $column ) = @_;
	my $renderer = 'builtin_render_cell_text';
	my $r        = undef;
	if ( defined( $self->columns->{$column}->{renderer} ) ) {
		$r = $self->columns->{$column}->{renderer};
	} elsif ( defined( $self->column_defaults->{renderer} ) ) {
		$r = $self->column_defaults->{renderer};
	}
	if ($r) {
		if ( $r =~ /^:/ ) {
			$r =~ s/^:/builtin_render_cell_/;
		}
		$renderer = $r;
	}
	my $content = $self->$renderer( $row, $column );
	return $content;
}

1;