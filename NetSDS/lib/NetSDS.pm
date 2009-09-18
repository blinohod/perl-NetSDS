#===============================================================================
#
#         FILE:  NetSDS.pm
#
#  DESCRIPTION:  NetSDS framework
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  24.04.2008 11:42:42 EEST
#===============================================================================

package NetSDS;

use 5.8.0;
use strict;
use warnings;

use version; our $VERSION = '1.205';

1;

=head1 NAME 

B<NetSDS> - Service Delivery Suite by Net Style

=head1 DESCRIPTION

C<NetSDS> is a flexible framework for rapid software development using
the following technologies:

=over

=item B<Perl5> - default programming language

=item B<PostgreSQL> - default DBMS

=item B<Apache> - HTTP server with FastCGI support

=item B<Kannel> - SMS and WAP gateway

=item B<Asterisk> - VoIP / telephony applications

=back

=head1 COMPONENTS

=over

=item * L<NetSDS::Class::Abstract> - abstract class for other NetSDS classes.

=item * L<NetSDS::App> - common application framework class.

=item * L<NetSDS::App::FCGI> - FastCGI applicatrion framework

=item * L<NetSDS::Conf> - configuration files management class.

=item * L<NetSDS::Logger> - syslog API.

=back

=head1 AUTHORS

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 THANKS

Valentyn Solomko <pere@pere.org.ua> - for Wono project

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

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

