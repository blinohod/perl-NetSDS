package NetSDS::Render::Table::Editable;

use base qw(NetSDS::Render::Table);

__PACKAGE__->mk_class_accessors(qw(edit_url));

sub format_table_start {
	my ( $self, %params ) = @_;
	$params{'ns:edit_url'} = $self->class()->edit_url();
	return $self->next::method(%params) if $self->next::can();
	return $self->start_tag( 'table', %params );
}

sub format_header_cell {
	my ( $self, $column, %params ) = @_;
	my @classes = defined( $params{class} ) ? split( /\s+/, $params{class} ) : ();
	if ( !$self->column_parameter( $column, 'readonly' ) ) {
		push @classes, 'editable';
		$params{'ns:readonly'} = '0';
		$params{'ns:editor'} = $self->column_parameter( $column, 'editor', 'plain' );
	} else {
		$params{'ns:readonly'} = '1';
	}
	$params{class} = join ' ', @classes;
	return $self->next::method( $column, %params );
}

1;
