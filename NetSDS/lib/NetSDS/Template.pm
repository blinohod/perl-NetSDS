#===============================================================================
#
#         FILE:  Template.pm
#
#  DESCRIPTION:  Wrapper for HTML::Template::Pro
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
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
use NetSDS::Util::File;

use version; our $VERSION = '1.205';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([%params])> - class constructor

This concstructor loads template files and parse them.

    my $tpl = NetSDS::Template->new(
		dir => '/etc/NetSDS/templates',
		esc => 'URL', 
		include_path => '/mnt/floppy/templates',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# Get filenames of templates
	my $tpl_dir = $params{dir};

	# Initialize templates hash reference
	my $tpl = {};

	my @tpl_files = @{ dir_read( $tpl_dir, 'tmpl' ) };

	# Add support for 'include_path' option
	foreach my $file (@tpl_files) {

		# Read file to memory
		if ( $file =~ /(^.*)\.tmpl$/ ) {

			# Determine template name and read file content
			my $tpl_name    = $1;
			my $tpl_content = file_read("$tpl_dir/$file");

			if ($tpl_content) {

				# Create template processing object
				my $tem = HTML::Template::Pro->new(
					scalarref              => \$tpl_content,
					filter                 => $params{filter} || [],
					loop_context_vars      => 1,
					global_vars            => 1,
					default_escape         => defined( $params{esc} ) ? $params{esc} : 'HTML',
					search_path_on_include => 1,
					path                   => [
						$params{include_path} . '',        # implicit path definition
						$params{dir} . '/inc',             # search inside subcatalog 'inc'
						'/usr/share/NetSDS/templates/',    # global templates
					]
				);

				$tpl->{$tpl_name} = $tem;
			}

		} ## end if ( $file =~ /(^.*)\.tmpl$/)

	} ## end foreach my $file (@tpl_files)

	# Create myself at last :)
	return $class->SUPER::new( templates => $tpl );

} ## end sub new

#***********************************************************************

=item B<render($tmpl_name, %params)> - render template with paramters

	my $str = $tmp->render('main', title => 'Main Page');

=cut

#-----------------------------------------------------------------------

sub render {

	my ( $self, $name, %params ) = @_;

	my $tpl = $self->{'templates'}->{$name};

	unless ($tpl) {
		return $self->error("Wrong template name: '$name'");
	}

	$tpl->clear_params();
	$tpl->param(%params);

	return $tpl->output;
}

1;

__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


