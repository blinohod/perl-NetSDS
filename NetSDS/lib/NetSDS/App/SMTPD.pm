package NetSDS::App::SMTPD;

use strict;
use warnings;

package NSocket;

use IO::Socket;
use base 'NetSDS::App';

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	return $self->create_socket($args{'port'});
};

sub create_socket {
	my $self = shift;
	my $socket = IO::Socket->new;
	
	$socket->socket(PF_INET, SOCK_STREAM, scalar getprotobyname('tcp'));
	$socket->blocking(0);
	$self->{'_socket'} = $socket;
	return $self;
};

sub get_socket_handle { +shift->{'_socket'} };
sub close { +shift->get_socket_handle->close };

package NClient;

use Net::Server::Mail::SMTP;
use base 'NSocket';

sub set_smtp {
	my $self = shift;
	
	$self->{'_smtp'} = Net::Server::Mail::SMTP->new( socket => $self->get_socket_handle );
	return $self;
};

sub set_callback { +shift->get_smtp->set_callback(@_) };
sub process      { +shift->get_smtp->process(@_) };
sub get_smtp     { +shift->{'_smtp'} };
sub get_header   { $_[0]->{'headers'}{lc $_[1]} };
sub get_msg      { +shift->{'msg'} };

sub get_mail {
	my ($self, $data) = @_;
	my @lines = split /\r\n/, $$data;
	
	$self->{'headers'} = {};
	my $i;

	for ($i = 0; $lines[$i]; $i++) {
		my ($key, $value) = split /:\s*/, $lines[$i];
		$self->{'headers'}{lc $key} = $value; #TODO fix me could be several Received
	}

	$self->{'msg'} = join "\r\n", @lines[$i + 1 .. $#lines];
	return 1;
};

package NetSDS::App::SMTPD; 

use base 'NSocket';
use IO::Socket;

sub create_socket {
	my ($self, $port) = @_;
	$port ||= 2525;
	return unless $port;

	$self->SUPER::create_socket;
	
	setsockopt ($self->get_socket_handle, SOL_SOCKET, SO_REUSEADDR, 1);
	bind ($self->get_socket_handle, sockaddr_in($port, INADDR_ANY)) or die "Can't use port $port";
	listen ($self->get_socket_handle, SOMAXCONN) or die "Can't listen on port: $port";
	
	$self->{'count'} = 0; #TODO remove
	return $self;
};

sub can_read {
	my $self = shift;
	my $rin = '';

	vec($rin, fileno($self->get_socket_handle), 1) = 1;
	return select($rin, undef, undef, undef);
};

sub accept {
	my $self = shift;
	$self->can_read;
 	$self->{'time'} = time unless $self->{'count'}; #TODO remove
	
	my $client = NClient->new;
	my $peer = accept($client->get_socket_handle, $self->get_socket_handle);
	
	if ($peer) {
		$self->speak("connection from ip [" . (inet_ntoa((sockaddr_in($peer))[1])) . "]");
	
		$client->set_smtp;
		$client->set_callback(DATA => \&data, $client);
		
		$self->{'count'}++; #TODO remove
		return $client;
	};
};

sub data {
	my ($smtp, $data) = @_;
	return $smtp->{'_context'}->get_mail($data);
};

sub process {
	my $self = shift;
	my $client = $self->accept;

	return unless $client;
	$client->process;
	#do something with msg
	$client->close;
	
	#TODO remove
	if ($self->{'count'} == 1000) {
		warn (($self->{'time'} - time)/$self->{'count'});
		die;
	};
	#end TODO
	
	return $self;
};

1;
