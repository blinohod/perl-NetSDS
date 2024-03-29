#!/usr/bin/env perl

=head1 NAME

Build.PL - Build script generator for NetSDS core libraries

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
	dist_version       => '2.0',
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
		'version'                => '0.700',
		'CGI'                    => '3.29',
		'CGI::Cookie'            => '0',
		'CGI::Fast'              => '0',
		'DBI'                    => '1.600',
		'DBD::Pg'                => '0',
		'DBD::mysql'             => '0',
		'Class::Accessor'        => '0',
		'Class::Accessor::Class' => '0',
		'Config::General'        => '0',
		'Data::Structure::Util'  => '0',
		'FCGI'                   => '0.67',
		'Getopt::Long'           => '0',
		'HTML::Template::Pro'    => '0.81',
		'IO::Socket'             => '0',
		'Iterator'               => '0.03',
		'Iterator::Util'         => '0.02',
		'JSON'                   => '2.0',
		'JSON::XS'               => '2.0',
		'LWP::UserAgent'         => '2.00',
		'POSIX'                  => '0',
		'Proc::Daemon'           => '0.03',
		'Proc::PID::File'        => '0',
		'Unix::Syslog'           => '1.0',
		'URI::Escape'            => '0',
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
