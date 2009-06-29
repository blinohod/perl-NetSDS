#===============================================================================
#
#         FILE:  Template.pm
#
#  DESCRIPTION:
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  16.07.2008 23:30:12 EEST
#===============================================================================

=head1 NAME

NetSDS::Template - NetSDS template engine

=head1 SYNOPSIS

	use NetSDS::Template;

=head1 DESCRIPTION

C<NetSDS::Template> class provides developers with ability to create template
based web applications.

=cut

package NetSDS::Template;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::Class::Abstract);

use HTML::Template::Pro;

use NetSDS::Util::File qw(
  path_read
  file_read
);

use version; our $VERSION = "1.0";
our @EXPORT_OK = qw();

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([%params])> - class constructor

This concstructor loads template files and parse them.

    my $tpl = NetSDS::Template->new(
		templates => {
			main => '/etc/tpl/main.tmpl',
			form1 => '/etc/tpl/form_one.tmpl',
		},
		filter => [], # no filtering
		esc => 'URL', # URL encoding
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# Get filenames of templates
	my %tpl_files = %{ $params{templates} };

	# Initialize templates hash reference
	my $tpl = {};

	foreach my $key ( keys %tpl_files ) {

		# Read file to memory
		my $file = $tpl_files{$key};
		my $txt  = file_read($file);

		if ( !$txt ) {
			warn "Cant read template file: $file\n";
			return undef;
		}

		# Create template processing object
		my $tem = HTML::Template->new(
			scalarref              => \$txt,
			filter                 => $params{filter} || [],
			loop_context_vars      => 1,
			global_vars            => 1,
			default_escape         => defined( $params{esc} ) ? $params{esc} : 'HTML',
			no_includes            => 1,
			search_path_on_include => 0,
		);

		unless ($tem) {
			return undef;
		}

		$tpl->{$key} = $tem;

	} ## end foreach my $key ( keys %tpl_files)

	# Create myself at last :)
	return $class->SUPER::new( %{$tpl} );

} ## end sub new

#***********************************************************************

=item B<render($tmpl_name, %params)> - render template with paramters

	my $str = $tmp->render('main', title => 'Main Page');

=cut

#-----------------------------------------------------------------------

sub render {

	my ( $this, $name, %params ) = @_;

	my $tpl = $this->{$name};

	unless ($tpl) {
		$this->error( "Wrong template '%s'", $name );
		return undef;
	}

	$tpl->clear_params;
	$tpl->param(%params);

	return $tpl->output;
}

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


