#===============================================================================
#
#         FILE:  Auth.pm
#
#  DESCRIPTION:
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  21.07.2008 16:25:58 EEST
#===============================================================================

=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::Auth;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::DB);

use version; our $VERSION = "1.0";
our @EXPORT_OK = qw();

use Digest::MD5;

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])>

Common constructor for all objects inherited from Wono.

    my $object = Wono::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(
		preps => {

			# Authenticate by login/password
			auth_passwd => 'select u.id from profiles.users u
				where login=? and password=?',

			# Authenticate by session key
			auth_session => 'select u.id as uid, s.id as sid from profiles.users u
				join session s on (s.user_id = u.id)
				where (u.expire > now() or u.expire is null)
				and s.expire_time > now()
				and s.session=?',

			# Authenticate by session key
			auth_session_group => 'select u.id as uid, s.id as sid from profiles.users u
				join profiles.sessions s on (s.user_id = u.id)
				join profiles.user_groups gu on (gu.user_id = u.id)
				join profiles.groups g on (g.id = gu.group_id)
				where (u.expire > now() or u.expire is null)
				and s.expire_time > now()
				and s.session=? and g.name = ?',

			# Authenticate by login/password in group
			auth_passwd_group => 'select u.id from profiles.users u
				join profiles.user_groups gu on (gu.user_id = u.id)
				join profiles.groups g on (g.id = gu.group_id)
				where u.login=? and u.password = ? and g.name = ?
				and (u.expire > now() or u.expire is null)',

			# Get all users list
			get_users => 'select * from profiles.users',

			# Get users list by group
			get_group_users => 'select u.* from profiles.users u
				join profiles.user_groups ug on (ug.user_id = u.id)
				join profiles.groups g on (ug.group_id = g.id)
				where g.name = ?',

			# Get groups user participate
			get_user_groups => 'select g.id, g.name from profiles.groups g
				join profiles.user_groups ug on (ug.group_id = g.id)
				where ug.user_id = ?',

			# Get actions by group and service names
			get_group_actions => 'select a.* from profiles.actions a
				join profiles.group_rights gr on (gr.action_id = a.id)
				join profiles.services s on (a.service_id = s.id)
				join profiles.groups g on (a.group_id = g.id)
				where g.name = ? and s.name = ?',
		},
		%params,
		login  => undef,
		uid    => undef,
		groups => {},
	);

	__PACKAGE__->mk_accessors(qw/login uid groups/);

	return $this;

} ## end sub new

#-----------------------------------------------------------------------

sub auth_user {

	my ( $this, $login, $passwd, $group ) = @_;

	if ( my $uid = $this->get_one( 'auth_passwd_group', $login, $passwd, $group ) ) {
		$this->login($login);
		$this->uid($uid);
		$this->get_groups();
		return $uid;
	} else {
		$this->login(undef);
		$this->uid(undef);
		$this->groups( {} );
		return $this->error("Cant authenticate user: login=$login, group=$group");
	}

}

sub get_groups {

	my ($this) = @_;

	if ( $this->uid ) {
		foreach my $group ( @{ $this->get_all_hash( 'get_user_groups', $this->uid ) } ) {
			$this->{groups}->{ $group->{name} } = $group->{id};
		}
	} else {
		return $this->error("Cant get groups for undefined user");
	}

}

sub action_allowed {

	my ($this) = @_;

}


#***********************************************************************

=item B<_gen_session()> - generate session key

Returns: new session key as MD5 string

=cut 

#-----------------------------------------------------------------------

sub _gen_session {

	my ($this) = @_;

	my $md5 = new Digest::MD5();
	$md5->add($$ , time() , rand(time) );
	return $md5->hexdigest();

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


