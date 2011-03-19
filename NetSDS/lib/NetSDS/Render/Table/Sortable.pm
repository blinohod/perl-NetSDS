package NetSDS::Render::Table::Sortable;

use base qw(NetSDS::Render::Table);

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
			$params{'ns:sorted'} = 1;
		}
		$params{'ns:sort_direction'} = $self->column_parameter( $column, 'sorted', 'asc' );
	}
	$params{class} = join ' ', @classes;
	return $self->next::method( $column, %params );
}

sub format_table_start {
	my ($self, %params) = @_;
	$params{'ns:sort_url'} = $self->class()->sort_url();
	return $self->next::method(%params) if $self->next::can();
	return $self->start_tag('table', %params);
}

1;
