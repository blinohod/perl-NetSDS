package NetSDS::Render::Table::Sortable;

use base qw(NetSDS::Render::Table);
use Data::Dumper;

__PACKAGE__->mk_class_accessors(qw(sort_url));

sub _switch_dir {
	my $param = shift;
	my $result = ( lc($param) eq 'asc' ) ? 'desc' : 'asc';
	return $result;
}

sub format_header_cell {
	my ( $self, $column, %params ) = @_;
	my @classes = defined( $params{class} ) ? split( /\s+/, $params{class} ) : ();
	if ( $self->column_parameter( $column, 'sortable' ) ) {
		push @classes, 'sortable';
		$params{'ns:sortable'} = '1';
		if ( $self->column_parameter( $column, 'sorted' ) ) {
			push @classes, $self->column_parameter( $column, 'sorted' );
			$params{'ns:sort_direction'} = _switch_dir( $self->column_parameter( $column, 'sorted' ) );
		} else {
			$params{'ns:sort_direction'} = 'asc';
		}
	}
	$params{class} = join ' ', @classes;
	return $self->wrap_tag( 'cell_head', $self->columns()->{$column}->{header_text}, %params );
}

sub format_table_start {
	my ($self) = @_;
	return $self->start_tag( "table", 'ns:sort_url' => $self->class()->sort_url() );
}

1;
