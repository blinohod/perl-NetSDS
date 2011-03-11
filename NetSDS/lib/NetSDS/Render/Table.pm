package NetSDS::Render::Table;

=pod


=cut

use version;
use warnings;
use strict;
use HTML::Entities;
our $VERSION = '1.0000';

use base qw/NetSDS::Class::Abstract/;
use mro 'c3';

__PACKAGE__->mk_accessors(qw(dataset));
__PACKAGE__->mk_class_accessors(qw(column_defaults table_defaults params head_defaults understands tags head_renderers foot_renderers columns defaults columns_order));
__PACKAGE__->columns(        [] );
__PACKAGE__->columns_order(  [] );
__PACKAGE__->head_renderers( [] );
__PACKAGE__->foot_renderers( [] );
__PACKAGE__->understands(    [ 'NetSDS::Render::Table::Type::Array', 'NetSDS::Render::Table::Type::Iterator' ] );
__PACKAGE__->tags(
	{
		'table'     => 'table',
		'thead'     => 'thead',
		'tbody'     => 'tbody',
		'row_head'  => 'tr',
		'row_body'  => 'tr',
		'row_foot'  => 'tr',
		'tfoot'     => 'tfoot',
		'cell_head' => 'th',
		'cell_body' => 'td',
		'cell_foot' => 'td'
	}
);

sub new {
	my $self = {};
	my ( $class, $dataset, %params ) = @_;
	bless $self, $class;
	$self->dataset( $self->convert_dataset($dataset) );
	$self->params( \%params );
	return $self;
}

sub convert_dataset {
	my ( $self, $dataset ) = @_;
	my $cls = $self->class();
	foreach my $package ( @{ $self->understands() } ) {
		eval {
			( my $pkg = $package ) =~ s|::|/|g;    # require need a path
			require "$pkg.pm";
			import $package;
		};
		die $@ if ($@);
		my $iter = eval { $package->new($dataset); };
		if ($iter) {
			return $iter;
		}
	}
	die "Cannot convert dataset to iterator.\n";
	return undef;
}

sub class {
	my $self = shift;
	return ref($self);
}

sub format_table_start {
	my ($self) = @_;
	my $fmt = "<%s %s>";
	if ( !defined( $self->params()->{classes} ) ) {
		$self->params()->{classes} = [];
	}
	my $classes = join ' ', 'grid', $self->params()->{classes};
	my $params = { class => 'grid' };
	return sprintf( $fmt, $self->tags()->{table}, _hash_to_attributes(%$params) );
}

sub format_table_end {
	my $self = shift;
	return sprintf( '</%s>', $self->tags()->{table} );
}

sub format_table_header {
	my $self = shift;
	my $container = sprintf( '<%s>%%s</%s>', $self->tags->{thead}, $self->tags->{thead} );
	# Filling in container includes
	# Rendering all header rows as put in head_renderers
	# Each such method is presumed to return a row.
	my @rows = ();
	foreach my $method ( @{ $self->head_renderers() ? $self->head_renderers() : [] } ) {
		push @rows, $self->$_();
	}
	# Rendering head columns
	push @rows, $self->format_table_header_columns();
	return sprintf( $container, join( "\n", @rows ) );
}

sub format_table_header_columns {
	my $self      = shift;
	my $container = sprintf( "<%s>%%s</%s>", $self->tags()->{row_head}, $self->tags()->{row_head} );
	my @columns   = ();
	foreach my $column ( @{ $self->columns_order } ) {
		push @columns, $self->format_header_cell($column);
	}
	return sprintf( $container, join( "", @columns ) );
}

sub format_header_cell {
	my ( $self, $column ) = @_;
	my $container = sprintf( '<%s %%s>%%s</%s>', $self->tags()->{cell_head}, $self->tags()->{cell_head} );
	my $attributes = '';
	return sprintf( $container, $attributes, $self->columns()->{$column}->{header_text} );
}

sub format_table_footer {
	my $self = shift;
	my $container = sprintf( '<%s>%%s</%s>', $self->tags->{tfoot}, $self->tags->{tfoot} );
	# Filling in container includes
	# Rendering all header rows as put in head_renderers
	# Each such method is presumed to return a row.
	my @rows = map { $_ = $self->$_(); } @{ $self->foot_renderers() };
	return sprintf( $container, join( "\n", @rows ) );
}

sub value {
	my $self = shift;
	if ( !defined( $self->{__render_state} ) ) {
		$self->{__render_state} = 'head';
		return $self->format_table_start();
	} elsif ( $self->{__render_state} eq 'head' ) {
		$self->{__render_state} = 'body_start';
		return $self->format_table_header();
	} elsif ( $self->{__render_state} eq 'body_start' ) {
		$self->{__render_state} = 'body';
		return sprintf( "<%s>", $self->tags->{tbody} );
	} elsif ( $self->{__render_state} eq 'body' ) {
		if ( $self->dataset->isnt_exhausted ) {
			my $row = $self->dataset->value();
			return $self->format_table_body_row($row);
		} else {
			$self->{__render_state} = 'foot';
			return sprintf( "</%s>", $self->tags->{tbody} );
		}
	} elsif ( $self->{__render_state} eq 'foot' ) {
		$self->{__render_state} = 'exhausted';
		return $self->format_table_footer() . $self->format_table_end();
	}
} ## end sub value

sub format_table_body_row {
	my ( $self, $row ) = @_;
	my $container = sprintf( '<%s>%%s</%s>', $self->tags->{row_body}, $self->tags->{row_body} );
	my @cells = map { $self->format_table_body_cell( $row, $_ ); } @{ $self->columns_order };
	return sprintf( $container, join( "", @cells ) );
}

sub format_table_body_cell {
	my ( $self, $row, $column ) = @_;
	my $container = sprintf( '<%s>%%s</%s>', $self->tags->{cell_body}, $self->tags->{cell_body} );
	my $renderer  = 'builtin_render_cell_text';
	my $r         = undef;
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
	return sprintf( $container, $content );
}

sub builtin_render_cell_text {
	my ( $self, $row, $column ) = @_;
	my $value = $row->{$column};
	return HTML::Entities::encode($value);
}

sub is_exhausted {
	my $self = shift;
	return ( defined( $self->{__render_state} ) && ( $self->{__render_state} eq 'exhausted' ) );
}

sub isnt_exhausted {
	my $self = shift;
	return !$self->is_exhausted;
}

sub _hash_to_attributes {
	my %hash = @_;
	my @results;
	my $fmt = '%s="%s"';
	foreach my $key ( keys %hash ) {
		push @results, sprintf( $fmt, HTML::Entities::encode($key), HTML::Entities::encode( $hash{$key} ) );
	}
	return join " ", @results;
}

1;
