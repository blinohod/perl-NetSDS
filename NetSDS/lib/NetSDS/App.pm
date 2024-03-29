
=head1 NAME

B<NetSDS::App> - common application superclass

=head1 SYNOPSIS

	#!/usr/bin/env perl
	
	use 5.8.0;
	use warnings;
	use strict;

	MyApp->run(
		conf_file => '/etc/NetSDS/myapp.conf', # default place for config search
		daemon => 1,      # run in daemon mode
		use_pidfile => 1, # write PID file to avoid double processing
		verbose => 0,     # no verbosity
	);

	1;

	# Application logic here
	package MyApp;

	use base 'NetSDS::App';

	# Startup hook
	sub start {
		my ($this) = @_;

		# Use configuration
		$this->{listen_port} = $this->conf->{listen_port};

		# Use logging subsystem
		$this->log("info", "Application successfully started with PID=".$this->pid);
	}

	# Main processing hook
	sub process {
		my ($this) = @_;
		print "Hello!";

		# Use verbose output
		$this->speak("Trying to be more verbose");

	}

=head1 DESCRIPTION

C<NetSDS::App> is a base class for NetSDS applications.
It implements common functionality including the following:

	* initialization
	* configuration file processing
	* command line parameters processing
	* application workflow
	* daemonization
	* PID file processing
	* logging
	* event detail records writing
	* default signal handling

New application should be inherited from C<NetSDS::App> class
directly or via child classes for more specific tasks like
CGI, AGI, SMPP and other.

Common application workflow is described on this diagram:

	App->run(%params)
	   |
	initialize()
	   |
	   ----------
	   |        |
	start()     |
	   |        |
	process()   --- main_loop()
	   |        |
	stop()      |
	   |        |
	   ----------
	   |
	finalize()

When application is starting C<initialize()> method is invoked first.
It provides common start time functionality like CLI parameters processing,
daemonization, reading configuration.

C<initialize()> method may be overwritten in more specific frameworks
to change default behaviour of some application types.

Then C<main_loop()> method invoked to process main application logic.
This method provides three redefinable hooks: C<start()>, C<process()> and C<stop()>.
Theese hooks should be overwritten to implement necessary logic.

=over

=item * B<start()> - start time hook

=item * B<process()> - process iteration hook

=item * B<stop()> - finish time hook

=back

Depending on C<infinite> flag main_loop() may call process() hook
in infinite loop or only once.

C<main_loop()> workflow may be redefined in inherited framework to implement
some other process flow logic.

On the last step C<finalize()> method is invoked to make necessary
finalization actions on framework level.

=head1 STARTUP PARAMETERS

Application class may be provided with a number of parameters that allows to manage application behaviour.
For example it may be a configuration file, daemonization mode or debugging flag.

Such parameters are passed to run() method as hash:

	MyApp->run(
		has_conf => 1,
		conf_file => '/etc/sample/file.conf',
		daemon => 1,
		use_pidfile => 1,
	);

=over

=item * B<has_conf> - 1 if configuration file is required (default: yes)

Mostly our applications requires configuration files but some of them
doesn't require any configuration (e.g. small utilities, etc).
Set C<has_conf> parameter to 0 to avoid search of configuration file.

=item * B<conf_file> - default path to configuration file (default: autodetect)

This parameter allows to set explicitly path to configuration file.
By default it's determined from application name and is looking like
C</etc/NetSDS/{name}.conf>

=item * B<name> - application name (default: autodetect)

This name is used for config and PID file names, logging.
By default it's automatically detected by executable script name.

=item * B<debug> - 1 for debugging flag (default: no)

=item * B<daemon> - 1 for daemon mode (default: no)

=item * B<verbose> - 1 for verbose mode (default: no)

=item * B<use_pidfile> - 1 to use PID files (default: no)

=item * B<pid_dir> - path to PID files catalog (default: '/var/run/NetSDS')

=item * B<auto_features> - 1 for auto features inclusion (default: no)

This parameter should be set to 1 if you plan to use automatically plugged
application features. Read C<PLUGGABLE APPLICATION FEATURES> section below.

=item * B<infinite> - 1 for inifinite loop (default: yes)

=item * B<edr_file> - EDR (event detail records) file name (default: undef)

=back
 
=head1 COMMAND LINE PARAMETERS

Command line parameters may be passed to NetSDS application to override defaults.

=over

=item * B<--conf> - path to config file

=item * B<--[no]debug> - set debug mode

=item * B<--[no]daemon> - set daemon/foreground mode

=item * B<--[no]verbose> - set verbosity mode

=item * B<--name> - set application name

=back

These CLI options overrides C<conf_file>, C<debug>, C<daemon>, C<verbose> and C<name> default parameters
that are passed in run() method.

Examples:

	# Debugging in foreground mode
	./application --config=/etc/myapp.conf --nodaemon --debug

	# Set application name explicitly
	./application --name=myapp

=cut

package NetSDS::App;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::Class::Abstract';

use version; our $VERSION = '2.001';

use NetSDS::Logger;    # API to syslog daemon
use NetSDS::Conf;      # Configuration file processor
use NetSDS::EDR;       # Module writing Event Detail Records

use Proc::Daemon;      # Daemonization
use Proc::PID::File;   # Managing PID files
use Getopt::Long qw(:config auto_version auto_help pass_through);

use constant CONF_DIR => '/etc/NetSDS';

use POSIX;
use Carp;

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([%params])> - class constructor

Constructor is usually invoked from C<run()> class method.
It creates application object and set its initial properties
from oarameters passed as hash.

Standard parameters are:

	* name - application name
	* debug - set to 1 for debugging
	* daemon - set to 1 for daemonization
	* verbose - set to 1 for more verbosity
	* use_pidfile - set to 1 for PID files processing
	* pid_dir - path to PID files catalog
	* conf_file - path to configuration file
	* has_conf - set to 1 if configuration file is necessary
	* auto_features - set to 1 for auto features inclusion
	* infinite - set to 1 for inifinite loop

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(
		name          => undef,                # application name
		pid           => $$,                   # proccess PID
		debug         => undef,                # debug mode flag
		daemon        => undef,                # daemonize if 1
		verbose       => undef,                # be more verbose if 1
		use_pidfile   => undef,                # check PID file if 1
		pid_dir       => '/var/run/NetSDS',    # PID files catalog (default is /var/run/NetSDS)
		conf_file     => undef,                # configuration file name
		conf          => undef,                # configuration data
		logger        => undef,                # logger object
		has_conf      => 1,                    # is configuration file necessary
		auto_features => 0,                    # are automatic features allowed or not
		infinite      => 1,                    # is infinite loop
		edr_file      => undef,                # path to EDR file
		%params,
	);

	return $this;

} ## end sub new

#***********************************************************************

=item B<run(%parameters)> - application launcher

This method calls class constructor and then switch to C<main_loop()> method.

All method parameters are transparently passed to application constructor.

	#!/usr/bin/env perl
	
	use 5.8.0;
	use warnings;
	use strict;

	MyApp->run(
		conf_file => '/etc/myapp.conf',
		daemon => 1,
		use_pidfile => 1,
	);

	1;

	# **********************************
	# Logic of application

	package MyApp;
	use base 'NetSDS::App';
	1;

=cut

#-----------------------------------------------------------------------
sub run {

	my $class = shift(@_);

	# Create application instance
	if ( my $app = $class->new(@_) ) {

		# Framework initialization
		$app->initialize(@_);

		# Application workflow
		$app->main_loop();

		# Framework finalization
		$app->finalize();

	} else {

		carp "Can't start application";
		return undef;

	}

} ## end sub run

#***********************************************************************

=item B<name([$name])> - application name

This method is an accessor to application name allowing to retrieve
this or set new one.

	print "My name is " . $this->name;

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('name');

#***********************************************************************

=item B<pid()> - PID of application process 

Read only access to process identifier (PID).

	print "My PID is " . $this->pid;

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_ro_accessors('pid');

#***********************************************************************

=item B<debug()> - debugging flag

This method provides an accessor to debugging flag.
If application called with --debug option it will return TRUE value.

	if ($this->debug) {
		print "Debug info: " . $debug_data;
	}

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_ro_accessors('debug');

#***********************************************************************

=item B<verbose()> - verbosity flag

This method provides an accessor to verbosity flag.

It may be used to increase application verbosity level if necessary.

	if ($this->verbose) {
		print "I'm working!";
	};

NOTE: This flag is is for normal operations. If you need implement debug 
output or other development/testing functionality - use debug() instead.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_ro_accessors('verbose');

#***********************************************************************

=item B<logger()> - accessor to logger

This method is accessor to logger (object of L<NetSDS::Logger> class).

NOTE: There is no need to use this method directly in application. See C<log()>
method description to understand logging features.

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('logger');

#***********************************************************************

=item B<conf()> - accessor to configuration

This method is accessor to application configuration represented as
hash reference returned by L<NetSDS::Conf> module.

Configuration sample:

	------------------------
	content_dir /var/lib/content

	<kannel>
		send_url http://127.0.0.1:13013/
		login netsds
		passwd topsecret
	</kannel>
	------------------------

Code sample:

	# Retrieve configuration
	my $content_dir = $this->conf->{content_dir};
	my $kannel_url = $this->conf->{kannel}->{send_url};

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('conf');

#***********************************************************************

=item B<use_pidfile(BOOL)> - PID file checking flag

Paramters: TRUE if PID file checking required

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('use_pidfile');

#***********************************************************************

=item B<pid_dir([$directory])> - PID files storage

Paramters: directory name

	$app->pid_dir("/var/run");

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('pid_dir');
#***********************************************************************

=item B<daemon(BOOL)> - daemonization flag

Paramters: TRUE if application should be a daemon

	if ($this->daemon()) {
		$this->log("info", "Yeah! I'm daemon!");
	};

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_ro_accessors('daemon');

#***********************************************************************

=item B<auto_features()> - auto features flag

Automatic features inclusion allowed if TRUE.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_ro_accessors('auto_features');

#***********************************************************************

=item B<infinite([$bool])> - is application in infinite loop

Example:

	# Switch to infinite loop mode
	$app->infinite(1);

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('infinite');

#***********************************************************************

#***********************************************************************

=item B<edr_file([$file_name])> - accessor to EDR file name

Paramters: EDR file path

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('edr_file');

#***********************************************************************

=item B<initialize()>

Common application initialization:

1. Reading config if necessary.

2. Daemonize application.

3. Check PID file for already running application instances.

4. Start logger.

5. Prepare default signal handlers.

=cut

#-----------------------------------------------------------------------
sub initialize {
	my ( $this, %params ) = @_;

	$this->speak("Initializing application.");
	# Determine application name from process name
	if ( !$this->{name} ) {
		$this->_determine_name();
	}

	# Get CLI parameters
	$this->_get_cli_param();

	# Daemonize, if needed
	if ( $this->daemon() ) {
		$this->speak("Daemonize, switch verbosity to false.");
		$this->{verbose} = undef;
		Proc::Daemon::Init;
	}

	# Update PID if necessary
	$this->{pid} = $$;

	# Create syslog handler
	if ( !$this->logger ) {
		$this->logger( NetSDS::Logger->new( name => $this->{name} ) );
		$this->log( "info", "Logger started" );
	}

	# Initialize EDR writer
	if ( $this->edr_file ) {
		$this->{edr_writer} = NetSDS::EDR->new( filename => $this->edr_file );
	}

	# Process PID file if necessary
	if ( $this->use_pidfile() ) {
		if ( Proc::PID::File->running( dir => $this->pid_dir, name => $this->name ) ) {
			$this->log( "error", "Application already running, stop immediately!" );
			die "Application already running, stop immediately!";
		}
	}

	# Initialize configuration
	if ( $this->{has_conf} ) {
		# Automatically determine configuration file name
		if ( !$this->{conf_file} ) {
			$this->{conf_file} = $this->config_file( $this->{name} . ".conf" );
		}
		$this->log( "info", "Conffile: " . $this->{conf_file} );

		# Get configuration file
		if ( my $conf = NetSDS::Conf->getconf( $this->{conf_file} ) ) {
			$this->conf($conf);
			$this->log( "info", "Configuration file read OK: " . $this->{conf_file} );
		} else {
			$this->log( "error", "Can't read configuration file: " . $this->{conf_file} );
		}

		# Add automatic features
		if ( $this->auto_features ) {
			$this->use_auto_features();
		}

	} ## end if ( $this->{has_conf})

	# Add signal handlers
	$SIG{INT} = sub {
		$this->speak("SIGINT caught");
		$this->log( "warn", "SIGINT caught" );
		$this->{to_finalize} = 1;
	};

	$SIG{TERM} = sub {
		$this->speak("SIGTERM caught");
		$this->log( "warn", "SIGTERM caught" );
		$this->{to_finalize} = 1;
	};

} ## end sub initialize

#***********************************************************************

=item B<use_auto_features()> - add features to application

This method implements automatic features inclusion by application
configuration file (see C<feature> sections).

=cut 

#-----------------------------------------------------------------------

sub use_auto_features {

	my ($this) = @_;

	if ( !$this->auto_features ) {
		return $this->error("use_auto_features() called without setting auto_features property");
	}

	# Check all sections <feature name> in configuration
	if ( $this->conf and $this->conf->{feature} ) {
		my @features = ( keys %{ $this->conf->{feature} } );

		foreach my $f (@features) {
			my $f_conf = $this->conf->{feature}->{$f};
			my $class  = $f_conf->{class};

			# Really add feature object
			$this->add_feature( $f, $class, $f_conf );

		}
	}

} ## end sub use_auto_features

#***********************************************************************

=item B<add_feature($name, $class, $config, %params)> - add feature

Paramters: feature name, class name, parameters (optional)

Returns: feature object

	$this->add_feature('kannel','NetSDS::Feature::Kannel', $this->conf->{feature}->{kannel});
	$this->kannel->send(.....);

=cut 

#-----------------------------------------------------------------------

sub add_feature {

	my $this  = shift @_;
	my $name  = shift @_;
	my $class = shift @_;
	my $conf  = shift @_;

	# Try to use necessary classes
	eval "use $class";
	if ($@) {
		return $this->error( "Can't add feature module $class: " . $@ );
	}

	# Feature class invocation
	eval {
		# Create feature instance
		$this->{$name} = $class->create( $this, $conf, @_ );
		# Add logger
		$this->{$name}->{logger} = $this->logger;
	};
	if ($@) {
		return $this->error( "Can't initialize feature module $class: " . $@ );
	}

	# Create accessor to feature
	$this->mk_accessors($name);

	# Send verbose output
	$this->speak("Feature added: $name => $class");

	# Write log message
	$this->log( "info", "Feature added: $name => $class" );

} ## end sub add_feature

#***********************************************************************

=item B<finalize()> - switch to finalization stage

This method called if we need to finish application.

=cut

#-----------------------------------------------------------------------
sub finalize {
	my ( $this, $msg ) = @_;

	$this->log( 'info', 'Application stopped' );

	exit(0);
}

#***********************************************************************

=item B<start()> - user defined initialization hook

Abstract method for postinitialization procedures execution.

Arguments and return defined in inherited classes.
This method should be overwritten in exact application.

Remember that start() methhod is invoked after initialize()

=cut

#-----------------------------------------------------------------------
sub start {

	my ( $this, %params ) = @_;

	return 1;
}

#***********************************************************************

=item B<process()> - main loop iteration hook

Abstract method for main loop iteration procedures execution.

Arguments and return defined in inherited classes.

This method should be overwritten in exact application.

=cut

#-----------------------------------------------------------------------
sub process {

	my ( $this, %params ) = @_;

	return 1;
}

#***********************************************************************

=item B<stop()> - post processing hook

This method should be rewritten in target class to contain real
post processing routines.

=cut

#-----------------------------------------------------------------------
sub stop {
	my ( $this, %params ) = @_;

	return 1;
}

#***********************************************************************

=item B<main_loop()> - main loop algorithm

This method provide default main loop alghorythm implementation and may
be rewritten for alternative logic.

=back

=cut

#-----------------------------------------------------------------------
sub main_loop {
	my ($this) = @_;

	# Run startup hooks
	my $ret = $this->start();

	# Run processing hooks
	while ( !$this->{to_finalize} ) {

		# Call production code
		$ret = $this->process();

		# Process infinite loop
		unless ( $this->{infinite} ) {
			$this->{to_finalize} = 1;
		}
	}

	# Run finalize hooks
	$ret = $this->stop();

} ## end sub main_loop

#***********************************************************************

=head1 LOGGING AND ERROR HANDLING

=over

=item B<log($level, $message)> - write message to log

This method provides ablity to write log messages to syslog.

Example:

	$this->log("info", "New message arrived with id=$msg_id");

=cut

#-----------------------------------------------------------------------
sub log {

	my ( $this, $level, $message ) = @_;

	# Try to use syslog handler
	if ( $this->logger() ) {
		$this->logger->log( $level, $message );
	} else {
		# No syslog, send error to STDERR
		carp "[$level] $message";
	}

	return undef;

}    ## sub log

#***********************************************************************

=item B<error($message)> - return error with logging

This method extends inherited method functionality with automatically
logging this message to syslog.

Example:

	if (!$dbh->ping) {
		return $this->error("We have problem with DBMS");
	}

=cut 

#-----------------------------------------------------------------------

sub error {
	my ( $this, $message ) = @_;

	$this->log( "error", $message );
	return $this->SUPER::error($message);

}

#***********************************************************************

=item B<speak(@strs)> - verbose output

Paramters: list of strings to be written as verbose output

This method implements verbose output to STDOUT.

	$this->speak("Do something");

=cut 

#-----------------------------------------------------------------------

sub speak {

	my ( $this, @params ) = @_;

	if ( $this->verbose ) {
		print join( "", @params );
		print "\n";
	}
}

#***********************************************************************

=item B<edr($record [,$record..])> - write EDR

Paramters: list of EDR records to write

	$app->edr({
		event => "call",
		status => "rejected",
	});

=cut 

#-----------------------------------------------------------------------

sub edr {

	my ( $this, @records ) = @_;

	if ( $this->{edr_writer} ) {
		return $this->{edr_writer}->write(@records);
	} else {
		return $this->error("Can't write EDR to undefined destination");
	}

}

#-----------------------------------------------------------------------

#***********************************************************************

=item B<config_file($file_name)> - determine full configuration file name

=cut 

#-----------------------------------------------------------------------

sub config_file {

	my ( $this, $file_name ) = @_;
	my $conf_file;
	if ( $file_name =~ /^\// ) {
		$conf_file = $file_name;
	} else {

		# Try to find path by NETSDS_CONF_DIR environment
		my $file = ( $ENV{NETSDS_CONF_DIR} || $this->CONF_DIR || "/etc/NetSDS/" );
		$file =~ s/([^\/])$/$1\//;
		$conf_file = $file . $file_name;

		# Last resort - local folder (use for debug, not production)
		unless ( -f $conf_file && -r $conf_file ) {
			$conf_file = "./" . $file_name;
		}
	}

	return $conf_file;
} ## end sub config_file

# Determine application name from script name
sub _determine_name {

	my ($this) = @_;

	# Dont override predefined name
	if ( $this->{name} ) {
		return $this->{name};
	}

	$this->{name} = $0;    # executable script
	$this->{name} =~ s/^.*\///;               # remove directory path
	$this->{name} =~ s/\.(pl|cgi|fcgi)$//;    # remove standard extensions
	return $this->{name};
}

# Determine execution parameters from CLI
sub _get_cli_param {

	my ($this) = @_;

	my $conf    = undef;
	my $debug   = undef;
	my $daemon  = undef;
	my $verbose = undef;
	my $name    = undef;

	# Get command line arguments
	GetOptions(
		'conf=s'   => \$conf,
		'debug!'   => \$debug,
		'daemon!'  => \$daemon,
		'verbose!' => \$verbose,
		'name=s'   => \$name,
	);

	# Set configuration file name
	if ($conf) {
		$this->{conf_file} = $conf;
	}

	# Set debug mode
	if ( defined $debug ) {
		$this->{debug} = $debug;
	}

	# Set daemon mode
	if ( defined $daemon ) {
		$this->{daemon} = $daemon;
	}

	# Set verbose mode
	if ( defined $verbose ) {
		$this->{verbose} = $verbose;
	}

	# Set application name
	if ( defined $name ) {
		$this->{name} = $name;
	}

} ## end sub _get_cli_param

1;

__END__

=back

=head1 PLUGGABLE APPLICATION FEAUTURES

To add more flexibility to application development C<NetSDS::App> framework allows to add pluggable features.
Application feature is a class dynamically loaded into application using configuration file parameters.

To use application features developer should do the following:

* set auto_features run() parameter

* create C<feature> sections in application as described

* create feature classes inherited from L<NetSDS::Feature>

=head1 EXAMPLES

See samples/app.pl

=head1 BUGS

This module is a one bug itself :-)

=head1 SEE ALSO

L<NetSDS>, L<NetSDS::Class::Abstract>, L<NetSDS::Logger>

=head1 TODO

Fix and cleanup!

=head1 AUTHOR

Valentyn Solomko <val@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2011 Net Style Ltd.

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

