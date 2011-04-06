package NetSDS::Portal::Registry;

=pod

=head1 NAME

NetSDS::Portal::Registry — the registry of installed apps

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

=cut

use base 'NetSDS::Class::DBI';

sub new {
	my ($class, %params) = @_;
	my $self = $class->SUPER::new(%params);
	return $self;
}

sub list {
	my ($self, %params) = @_;
	my $query = "select * from portal.applications WHERE %s";
	my @where = ('1');
	my @bind = ();
	
}

1;
