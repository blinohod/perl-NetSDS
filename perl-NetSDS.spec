# This is spec file for common NetSDS frameworks

%define m_distro NetSDS
%define m_name NetSDS
%define m_author_id RATTLER
%define _enable_test 1
%def_without test


Name: perl-NetSDS
Version: 1.01
Release: alt3

Summary: Common Perl modules for NetSDS VAS framework
Summary(ru_RU.UTF-8): Общие модули Perl для VAS фремворка NetSDS

License: GPL

Group: Networking/Other
Url: http://www.netstyle.com.ua/

Packager: Michael Bochkaryov <misha@altlinux.ru>

BuildArch: noarch
Source0: %m_distro-%version.tar.gz

# Automatically added by buildreq on Tue Jun 16 2009 (-bi)
BuildRequires: perl-CGI perl-Class-Accessor-Class perl-Class-ErrorHandler perl-Clone perl-Config-General perl-DBI perl-Data-Structure-Util perl-Data-UUID perl-Encode perl-Excel-Template perl-FCGI perl-HTML-SimpleParse perl-HTML-Template-Pro perl-HTML-Tree perl-Module-Build perl-Proc-Daemon perl-Proc-PID-File perl-Test-Pod perl-Test-Pod-Coverage perl-Text-CSV_XS perl-TimeDate perl-Unix-Syslog

%description
NetSDS is an easy to use and flexible framework firstly intended
for mobile VAS developent but may be used as more common thing.

This package contains common Perl modules for NetSDS.

%description -l ru_RU.UTF-8
NetSDS - это гибкий и простой в использовании фреймворк, прежде всего
предназначенный для разработки мобильных VAS, но также может быть
использован в качестве фреймворка общего назначения.

Этот пакет содержит общие модули Perl для NetSDS

%prep
%setup -q -n %m_distro-%version

%build
%perl_vendor_build

%install
%perl_vendor_install

%pre

%files
%perl_vendor_privlib/NetSDS*
%perl_vendor_man3dir/*
%doc samples

%changelog
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
