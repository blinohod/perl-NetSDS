# This is spec file for common NetSDS frameworks

%define m_distro NetSDS
%define m_name NetSDS
%define m_author_id RATTLER
%define _enable_test 1
%def_without test


Name: perl-NetSDS
Version: 2.000
Release: alt2

Summary: Common Perl modules for NetSDS VAS framework
Summary(ru_RU.UTF-8): Общие модули Perl для VAS фремворка NetSDS

License: GPL

Group: Networking/Other
Url: http://www.netstyle.com.ua/

Packager: Dmitriy Kruglikov <dkr@netstyle.com.ua>

BuildArch: noarch
Source0: %m_name-%version.tar

BuildRequires: perl-libwww

# Automatically added by buildreq on Mon Mar 08 2010 (-bi)
BuildRequires: perl-CGI 
BuildRequires: perl-Cache-Memcached-Fast
BuildRequires: perl-Class-Accessor-Class
BuildRequires: perl-Class-ErrorHandler
BuildRequires: perl-Config-General
BuildRequires: perl-DBD-Pg
BuildRequires: perl-Data-UUID 
BuildRequires: perl-Data-Structure-Util
BuildRequires: perl-Exception-Class
BuildRequires: perl-FCGI
BuildRequires: perl-HTML-Template-Pro
BuildRequires: perl-JSON
BuildRequires: perl-JSON-XS
BuildRequires: perl-Locale-gettext
BuildRequires: perl-Log-Agent
BuildRequires: perl-Module-Build
BuildRequires: perl-Net-Server-Mail
BuildRequires: perl-Proc-Daemon
BuildRequires: perl-Proc-PID-File
BuildRequires: perl-Test-Pod
BuildRequires: perl-Test-Pod-Coverage
BuildRequires: perl-Unix-Syslog
BuildRequires: perl-Iterator

# Add implicit requirements
Requires: perl-FCGI
Requires: perl-DBD-Pg

%description
NetSDS is an easy to use and flexible framework firstly intended
for mobile VAS developent but may be used as more common thing.

This package contains common Perl modules for NetSDS:
* abstract class implementation
* abstract application

%description -l ru_RU.UTF-8
NetSDS - это гибкий и простой в использовании фреймворк, прежде всего
предназначенный для разработки мобильных VAS, но также может быть
использован в качестве фреймворка общего назначения.

Этот пакет содержит общие модули Perl для NetSDS

%add_findreq_skiplist */*template*/*pl

%prep
%setup -q -n %m_distro-%version

%build
%perl_vendor_build

%install
%perl_vendor_install

%pre

%files
%perl_vendor_privlib/NetSDS*
%doc samples Changes

%changelog
* Mon Oct 17 2011 Michael Dmitriy Kkkruglikov  <dkr@altlinux.ru> 2.000-alt2
- Clear build.

* Mon Oct 17 2011 Michael Dmitriy Kkkruglikov  <dkr@altlinux.ru> 2.000-alt1
- Build requirements fixed (perl-Iterator).

* Mon Oct 17 2011 Michael Bochkaryov <misha@altlinux.ru> 2.000-alt1
- Build requirements fixed (Exception::Class).

* Mon Oct 17 2011 Michael Bochkaryov <misha@altlinux.ru> 2.000-alt0
- version update to 2.000
- removed modules that aren't relevany to core functionality

* Fri May 27 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 1.400-alt3
- Update $VERSION to 1.403

* Thu May 26 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 1.400-alt2
- Removed unneded BuildRequires for perl-NetSDS-Utils

* Mon Mar 08 2010 Michael Bochkaryov <misha@altlinux.ru> 1.400-alt1
- NetSDS::LWP - simple wrapper around LWP HTTP library

* Tue Nov 10 2009 Michael Bochkaryov <misha@altlinux.ru> 1.301-alt1
- significantly improved POD documentation
- reimplemented NetSDS::Session
- implemented transactions support in DBI wrapper
- some minor fixes

* Mon Oct 26 2009 Michael Bochkaryov <misha@altlinux.ru> 1.300-alt1
- changed copyright (license unchanged)
- improved POD documentation
- added INTERVAL_MINUTE and LANG_DE constants
- fixed facility support in Logger.pm
- fixed error handling in NetSDS::DBI::_connect()
- removed clone() support from NetSDS::Class::Abstract (move to separate module)
- removed Class::Accessor inheritance due to Class::Accessor::Class do the same things
- simplified abstract constructor (now we accept only hashes)
- removed Storable based (de)serialization from abstract class
- implemented own error handling instead of Class::ErrorHandler
- updated testcases
- fixed some small bugs

* Tue Oct 13 2009 Michael Bochkaryov <misha@altlinux.ru> 1.206-alt1
- POD documentation improved
- added autoflushing in NetSDS::App::FCGI
- implement can_method() in JSRPC.pm to use instead of can()
- avoid log() call if can't execute one
- added "sql_debug" feature to NetSDS::DBI
- added fields list support to NetSDS::DBI::Table
- new NetSDS::EDR module to manage EDR files
- new NetSDS::Session module to manage sessions in MemcacheD
- new NetSDS::Translate wrapper to gettext
- new NetSDS::Template wrapper to HTML::Template::Pro

* Fri Sep 18 2009 Michael Bochkaryov <misha@altlinux.ru> 1.205-alt1
- added support for glob includes
- added UTF-8 support in config

* Wed Sep 16 2009 Michael Bochkaryov <misha@altlinux.ru> 1.204-alt1
- added NetSDS::App::SMTPD module
- updated POD documentation

* Sat Sep 12 2009 Michael Bochkaryov <misha@altlinux.ru> 1.203-alt1
- implemented EDR support for billing statistics
- switch off verbosity for daemons and FCGI

* Wed Aug 26 2009 Michael Bochkaryov <misha@altlinux.ru> 1.202-alt1
- fixed PID retrieving after daemonization
- added logging if already running
- removed config search in 'admin' directory
- removed stupid check for 'to_finalize' to set it

* Tue Aug 18 2009 Michael Bochkaryov <misha@altlinux.ru> 1.201-alt1
- NetSDS::DBI::Table implemented (simple API to SQL tables)

* Tue Aug 11 2009 Michael Bochkaryov <misha@altlinux.ru> 1.200-alt1
- added JSON-RPC framework
- improved POD documentation
- added logging to features (plugins)

* Sat Aug 08 2009 Michael Bochkaryov <misha@altlinux.ru> 1.102-alt1
- automate --version and --help processing (Getopt::Long based)
- pass through @ARGV to application

* Fri Aug 07 2009 Michael Bochkaryov <misha@altlinux.ru> 1.101-alt1
- Fix finalization detect in main_loop()

* Sat Aug 01 2009 Michael Bochkaryov <misha@altlinux.ru> 1.100-alt2
- NetSDS::DBI module added

* Thu Jul 23 2009 Michael Bochkaryov <misha@altlinux.ru> 1.020-alt2
- version changed due to Perl version naming specific

* Mon Jul 13 2009 Michael Bochkaryov <misha@altlinux.ru> 1.02-alt2
- drop modules for further moving to separate packages
- fix testcases
- fix POD documentation
- implement basic signal handlers in NetSDS::App
- implement infinite loop inside main_loop()

* Tue Jun 16 2009 Michael Bochkaryov <misha@altlinux.ru> 1.02-alt1
- ported to last Sisyphus

* Mon Dec 22 2008 Michael Bochkaryov <misha@altlinux.ru> 1.01-alt3
- speak() method implemented

* Sun Nov 16 2008 Michael Bochkaryov <misha@altlinux.ru> 1.01-alt2
- 1.01 release tag

* Sun Sep 28 2008 Michael Bochkaryov <misha@altlinux.ru> 1.00-alt2
- --name parameter support in NetSDS::App

* Sun Sep 07 2008 Michael Bochkaryov <misha@altlinux.ru> 1.00-alt1
- NetSDS::App improvements
  + add_feature()
	+ use_features()
- 1.00 release at last

* Wed Sep 03 2008 Michael Bochkaryov <misha@altlinux.ru> 0.9-alt2
- Build.PL fixed
- NetSDS::Common added

* Sun Aug 31 2008 Michael Bochkaryov <misha@altlinux.ru> 0.9-alt1
- 0.9 version - almost stable release
  * hashref support in constructor added
	* deserializer from Storable implementation
	* some code cleanup
- build requirements fixes

* Sun Aug 17 2008 Michael Bochkaryov <misha@altlinux.ru> 0.5-alt4
- NetSDS::Util::Misc updated
  + perldoc improved
	+ Hex, Base64, URI encoding functions
	+ UUID generation

* Sun Aug 17 2008 Michael Bochkaryov <misha@altlinux.ru> 0.5-alt4
- Date and time utilities ported
- perldoc improved

* Fri Aug 15 2008 Michael Bochkaryov <misha@altlinux.ru> 0.5-alt3
- new tag (0.5-alt3)

* Fri Aug 15 2008 Michael Bochkaryov <misha@altlinux.ru> 0.5-alt2
- NetSDS::DB::(Single|Collection) build fixed
- Buildreq updated

* Fri Aug 15 2008 Michael Bochkaryov <misha@altlinux.ru> 0.5-alt1
- auto_quoute feature added to NetSDS::DB::Table

* Thu Aug 14 2008 Michael Bochkaryov <misha@altlinux.ru> 0.4-alt5
- NetSDS::Util::Date updated with few functions
- NetSDS::Util::Text docs translated
- NetSDS::App::Admin updated

* Mon Aug 11 2008 Michael Bochkaryov <misha@altlinux.ru> 0.4-alt4
- lot of NetSDS::App::FCGI improvements
- FastCGI sample code added

* Mon Aug 11 2008 Michael Bochkaryov <misha@altlinux.ru> 0.4-alt3
- _gen_session() method added to NetSDS::Auth

* Mon Aug 11 2008 Michael Bochkaryov <misha@altlinux.ru> 0.4-alt2
- nstore() method added to NetSDS::Class::Abstract

* Sun Aug 10 2008 Michael Bochkaryov <misha@altlinux.ru> 0.4-alt1
- serialize() method added to NetSDS::Class::Abstract
- documentation improved

* Wed Jul 30 2008 Michael Bochkaryov <misha@altlinux.ru> 0.3-alt5
- moved to separate package perl-NetSDS-common

* Sun Jul 13 2008 Michael Bochkaryov <misha@altlinux.ru> 0.1-ns1
- first build for ALT Linux Sisyphus
