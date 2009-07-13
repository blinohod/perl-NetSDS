#!/usr/bin/env perl
########################################################################
# $Id: Build.PL 27 2008-07-21 23:23:15Z anvil $
########################################################################

=head1 NAME

Build.PL - Build script generator for NetSDS common

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings 'all';

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'NetSDS',
	dist_name          => 'NetSDS',
	dist_abstract      => 'Core Perl5 modules for NetSDS VAS development framework',
	create_makefile_pl => 'traditional',
	dist_author        => 'Net.Style Development Team <info@netstyle.com.ua>',
	create_readme      => 1,
	license            => 'gpl',
	build_requires     => {
		'Test::More'          => '0',
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
		'Module::Build'       => '0',
	},
	requires => {
		'perl'                   => '5.008',
		'version'                => '0',
		'CGI'                    => '0',
		'CGI::Cookie'            => '0',
		'CGI::Fast'              => '0',
		'FCGI'                   => '0',
		'Class::Accessor'        => '0',
		'Class::Accessor::Class' => '0',
		'Class::ErrorHandler'    => '0',
		'Clone'                  => '0',
		'Config::General'        => '0',
		'Data::Structure::Util'  => '0',
		'Getopt::Long'           => '0',
		'POSIX'                  => '0',
		'Proc::Daemon'           => '0',
		'Proc::PID::File'        => '0',
		'Storable'               => '0',
		'Unix::Syslog'           => '0',
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
