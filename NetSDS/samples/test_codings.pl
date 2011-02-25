#!/usr/bin/env perl

use warnings;
use strict;

use URI::Escape;

use NetSDS::Util::String qw(str_encode str_decode str_recode);

my $var = "жопа жопа жопа проверка связи 3-й раз блин не то бегает, что нескол";

$var = str_encode($var);

$var = str_decode($var, "UTF16-BE");

print length($var) . uri_escape($var,"\0-\xff");

