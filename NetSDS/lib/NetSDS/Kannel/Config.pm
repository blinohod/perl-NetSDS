
=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::Kannel::Config;

use 5.8.0;
use strict;
use warnings;

use NetSDS::Util::File;

use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = version->declare('v2.1.0');
our @EXPORT_OK = qw();

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new();

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('user');

sub load_part {

	my ( $this, $file ) = @_;

	my $orig = file_read($file);

	$orig =~ s/\r\n/\n/gs;

	my $grp = '';

	foreach my $str ( split /\n/, $orig ) {

		if ( $str =~ /^group\s*=\s*(\S+)\s*$/ ) {
			$grp = $1;
			$this->{$grp} = {};
		}

		next unless ($grp);
		next if ( $str =~ /^\s*\#/ );

		if ( $str =~ /\s*(\S+)\s*=\s*(\S.*)\s*$/ ) {
			my $key = $1;
			my $val = $2;
			#print "K [$key] V [$val]\n";
			$this->{$grp}->{$key} .= $val;
		}

	}
	#my @grp split /^group\s*=\s*\S+\s*

} ## end sub load_part

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


