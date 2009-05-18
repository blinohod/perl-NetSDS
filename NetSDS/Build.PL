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
		'Test::More'          => '0.62',
		'Test::Pod'           => '1.26',
		'Test::Pod::Coverage' => '1.08',
		'Module::Build'       => '0.2805',
	},
	requires => {
		'perl'                     => '5.008',
	},
	recommends   => {},
	script_files => {},
);

$build->create_build_script;

__END__

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
