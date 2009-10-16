package NetSDS::Session;

use 5.8.0;
use strict;
use warnings;

use Cache::Memcached::Fast;
use JSON;

sub SESSION_ID() { 0 };
sub MEMCACH()    { 1 };
sub SESSION()    { 2 };

sub new { 
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless [];
	return $self->init(\%args);
};

sub init {
	my ($self, $args) = @_;
	
	my $host = $args->{'host'};
	my $port = $args->{'port'};

	return $self unless $host and $port;
	
	$self->[ MEMCACH ] = new Cache::Memcached::Fast({
		servers => [ { address => "$host:$port" } ],
		serialize_methods => [ \&JSON::encode_json, \&JSON::decode_json ],
	});

	return $self;
};

sub set_session { 
	my ($self, $session_id) = @_;
	
	@$self[ SESSION, SESSION_ID ] = (
		$self->_get( $session_id ) || undef, $session_id
	);
	
	$self->[ SESSION ] ||= {};
	return $self;
};

sub get_session { +shift->[ SESSION_ID ] };

sub set {
	my ($self, $key, $value) = @_;
	$self->[ SESSION ]->{$key} = $value;
	return 1;
};

sub get { 
	my ($self, $key) = @_;
	return $self->[ SESSION ]->{$key};
};

sub delete {
	my ($self, $key) = @_;
	return delete $self->[ SESSION ]->{$key};
};

sub close_session {
	my $self = shift;

	my $res = $self->[ MEMCACH ] ? $self->[ MEMCACH ]->set(
		$self->get_session, $self->[ SESSION ]) : undef;
	
	@$self[ SESSION, SESSION_ID ] = (undef, undef);
	return $res;
};

sub clear {
	my $self = shift;
	
	$self->[ SESSION ] = {};
	return unless $self->[ MEMCACH ];

	return $self->[ MEMCACH ]->delete($self->get_session);
};

sub _get { 
	my ($self, $key) = @_;
	return $self->[ MEMCACH ] ? $self->[ MEMCACH ]->get($key) : {};
};

1;

__END__

=head1 NAME

NetSDS::Session

=head1 SYNOPSYS

use NetSDS::Session

=head1 ITEMS

=over 4

=item B<SESSION_ID>

Current session_id;

=item B<MEMCACH>

object Cache::Memcached::Fast

=item B<SESSION>

session - a perl structure like this { order => desc, filter => non_active }

=item B<new>

Constructor. The object is an array ref. It takes a structure like this: 
{ host => 'localhost', port => 12211 }. Calls a sub when initializing of a memcached server
provides and returns the object NetSDS::Session.

	Example: 
	my $session = NetSDS::Session->new(
		host => 'localhost',
		port => '12211'
	);

=item B<init>

This method calls from a constructor. It provides an initializing the connection to a 
memcached server with params that has been taken by a constructor (params of a memcached server). 
Work with memcached server provides by an object Cache::Memcached::Fast. Params of a Cache::Memcached::Fast
object: 
	
	serialize_methods => [ \&JSON::encode_json, \&JSON::decode_json ],
	compress_threshold => -1,
	connect_timeout => 0.25,
	close_on_error => true,
	failure_timeout => 10 sec

Notice: If there is no host or port for memcached, it wouldn't be an error.
Returns an object NetSDS::Session in any case.

=item B<set_session>

This method takes a session_id of the user's session. According to a session_id (has session been stored
earlier and server params) there could be several cases:
	
	- when there is no session in server 
		initialize an empty hash ref {} for a new session.
	- when server is not initialize (this happens when you didn't gave a host or a port into constructor
		initialize an empty hash ref (similar to a previous case) but notice that this session wouldn't be stored
	- when session exists in server 
		get this session

	Example: 
		$session->set_session($session_id);

Returns an object NetSDS::Session

=item B<get_session>

Returns a current session_id.
	
	Example:
		$session->get_session

=item B<set>

Takes a key and value that should be added or replaced in current session. Notice: this method doesn't 
provide setting params into server. It's just connect with a perl-structure that has been get from a server
by set_session method. For storing session the method $session->close_session should be used.

	Example: 
		$session->set('order', 'id desc');

=item B<get>

Takes a key for a value that has been saved in session earlier or undef.

	Example:
		$session->get('order').

=item B<delete>

Takes a key that should be remover from current session.
	
	Example:
		$sessopn->delete('order');

=item B<close_session>

This method provides storing current session. In case that there is no server (host or port hasn;t been taken by
constructor), session wouldnt be stored.

	Example:
		$session->close_session.

After closing session you couldn't work with it.

=item B<clear>

This method deletes current session from server. 

=back 
