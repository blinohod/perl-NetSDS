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
	module_name        => 'NetSDS::Common',
	dist_name          => 'NetSDS-Common',
	dist_abstract      => 'NetSDS is an easy to use and flexible service delivery suite for telco VAS',
	create_makefile_pl => 'traditional',
	dist_author        => 'Net.Style Development Team <info@netstyle.com.ua>',
	create_readme      => 1,
	license            => 'gpl',
	build_requires     => {
		'Test::More'          => '0.62',
		'Test::Pod'           => '1.26',
		'Test::Pod::Coverage' => '1.08',
		'Module::Build'       => '0.2805',
	},
	requires => {
		'version'                  => '0.50',
		'perl'                     => '5.008',
		'Carp'                     => '1.04',
		'Clone'                    => '0.22',
		'Class::Accessor'          => '0.31',
		'Class::Accessor::Class'   => '0.501',
		'Class::Accessor::Grouped' => '0.08001',
		'Class::Accessor::Chained' => '0.01',
		'Config::General'          => '2.31',
		'CGI'                      => '3.37',
		'FCGI'                     => '0.67',
		'Data::Dumper'             => '2.121_08',
		'Data::Structure::Util'    => '0.12',
		'Date::Format'             => '2.22',
		'Date::Parse'              => '2.27',
		'DBD::Pg'                  => '1.49',
		'DBI'                      => '1.52',
		'Encode'                   => '2.12',
		'Exporter'                 => '5.58',
		'File::Copy'               => '2.09',
		'File::Path'               => '1.08',
		'File::Spec'               => '3.12',
		'Getopt::Long'             => '2.35',
		'HTTP::Cookies'            => '1.39',
		'HTTP::Date'               => '1.47',
		'HTTP::Status'             => '1.28',
		'IO::File'                 => '1.13',
		'MIME::Base64'             => '3.07',
		'Pod::Usage'               => '1.35',
		'POSIX'                    => '1.09',
		'Proc::Daemon'             => '0.03',
		'Proc::PID::File'          => '1.24',
		'Scalar::Util'             => '1.19',
		'Storable'                 => '2.15',
		'Text::CSV_XS'             => '0.23',
		'Time::Local'              => '1.11',
		'LWP::UserAgent'           => '2.033',
		'XML::LibXML'              => '1.58',
		'Unix::Syslog'             => '1.1',
		'Class::ErrorHandler'      => '0.01',
		'HTML::Template::Pro'      => '0.60'
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
