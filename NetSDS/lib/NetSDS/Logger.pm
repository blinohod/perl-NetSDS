#===============================================================================
#
#         FILE:  Logger.pm
#
#  DESCRIPTION:  Syslog wrapper for Net SDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  25.04.2008 17:32:37 EEST
#===============================================================================

=head1 NAME

NetSDS::Logger - syslog wrapper for applications and classes

=head1 SYNOPSIS

	use NetSDS::Logger;

	my $logger = NetSDS::Logger->new();
	$logger->log("info", "Syslog message here");

=head1 DESCRIPTION

This module contains implementation of logging functionality for NetSDS components.

By default, messages are logged with C<local0> facility and C<pid,ndelay,nowait> options.

B<NOTE>: C<NetSDS::Logger> module is for internal use mostly from application frameworks like C<NetSDS::App>, C<NetSDS::App::FCGI>, etc.

=cut

package NetSDS::Logger;

use 5.8.0;
use warnings;

use Unix::Syslog qw(:macros :subs);

use version; our $VERSION = '1.206';

#===============================================================================

=head1 CONSTRUCTOR

=over

=item B<new(%parameters)>

Constructor B<new()> creates new logger object and opens socket with default
NetSDS logging parameters.

Arguments allowed (as hash):

=over

=item B<name> - application name

This parameter may be used for identifying application in syslog messages

=item B<facility> - logging facility

If not set 'local0' is used as default value

=back

    my $object = NetSDS->new(%options);

=back 

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = {};

	# Set application identification name
	my $name = 'NetSDS';
	if ( $params{name} ) {
		$name = $params{name};
	}

	my $facility = LOG_LOCAL0;
	#if ( $params{facility} ) {
	#	$facility = $params{facility};
	#}

	openlog( $name, LOG_PID | LOG_CONS | LOG_NDELAY, $facility );
	#setlogsock('unix');

	return bless $self, $class;

} ## end sub new

#***********************************************************************

=head1 OBJECT/CLASS METHODS

=over

=item B<log($level, $message)> - write record to log

Wrapper to C<syslog()> method of L<Unix::Syslog> module.

Level is passed as string and may be one of the following:

	alert	- LOG_ALERT
	crit	- LOG_CRIT
	debug	- LOG_DEBUG
	emerg	- LOG_EMERG
	error	- LOG_ERR
	info	- LOG_INFO
	notice	- LOG_NOTICE
	warning	- LOG_WARNING

=cut

#-----------------------------------------------------------------------
sub log {

	my ( $self, $level, $message ) = @_;

	# Level aliases
	my %LEVFIX = (
		alert     => LOG_ALERT,
		crit      => LOG_CRIT,
		critical  => LOG_CRIT,
		deb       => LOG_DEBUG,
		debug     => LOG_DEBUG,
		emerg     => LOG_EMERG,
		emergency => LOG_EMERG,
		panic     => LOG_EMERG,
		err       => LOG_ERR,
		error     => LOG_ERR,
		inf       => LOG_INFO,
		info      => LOG_INFO,
		inform    => LOG_INFO,
		note      => LOG_NOTICE,
		notice    => LOG_NOTICE,
		warning   => LOG_WARNING,
		warn      => LOG_WARNING,
	);

	my $LEV = $LEVFIX{$level};

	if ( !$LEV ) {
		$LEV = LOG_INFO;
	}

	if ( !$message ) {
		$message = "";
	}

	syslog( $LEV, "[$level] $message" );

} ## end sub log

#***********************************************************************

=back

=head1 DESTRUCTOR

Destructor (DESTROY method) calls C<closelog()> function. That's all.

=cut

#-----------------------------------------------------------------------
sub DESTROY {

	closelog();

}

1;

__END__


=head1 EXAMPLES

See L<NetSDS::App> for example.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<Sys::Syslog>

=head1 TODO

1. Implement logging via UDP socket.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


