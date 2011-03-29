package NetSDS::Render::Table::SelectableRows;

use mro 'c3';
use base qw(NetSDS::Render::Table);

sub get_table_classes {
	my $self = shift;
	my $classes = $self->next::method();
	push @$classes, 'selectable-rows';
	return $classes;
}

sub get_table_row_cells {
	my ( $self, $row ) = @_;
	my $cells = [ $self->wrap_tag( 'cell_body', '<input type="checkbox" ns:row-selector="1" ns:select-row="' . $self->get_table_row_id($row) . '" />', class => 'row-selector' ), @{ $self->next::method($row) } ];
	return $cells;
}

sub get_table_header_columns {
	my ($self) = @_;
	my $columns = [ $self->wrap_tag( 'cell_head', '<input type="checkbox" ns:row-selector="all" />', class => 'row-selector' ), @{ $self->next::method() } ];
	return $columns;
}

1;
