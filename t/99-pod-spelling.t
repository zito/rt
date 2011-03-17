#!/usr/bin/env perl -w

use strict;
use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

# strip comments and empty lines
my @stopwords = grep { /\S/ } map { s/#.*//; $_ } <DATA>;

add_stopwords(@stopwords);

local $ENV{LC_ALL} = 'C';
set_spell_cmd('aspell list -l en');

all_pod_files_spelling_ok();

__DATA__
# PERSON NAMES
Autrijus
Falcone
Riggle
Ruslan
Zakirov

# ENGLISH
one's

# PROGRAMMING JARGON
API
APIs
CGI
CPAN
DBI
DSN
GPG
GnuPG
MUA
SQL
STDERR
STDOUT
TODO
UI
autohandler
checkboxes
datetime
dhandler
dropdown
filename
html
keyserver
login
logins
longblob
metadata
multipart
optree
paramhash
paramhash's
passphrase
perltidy
perltidyrc
plugin's
plugins
prepopulated
rebless
reblesses
resultset
runtime
startup
subdirectory
tuple
tuples
unicode
unix
username
workflow
hostname
Mozilla's
Intercal
subclause
longtext
ENTRYAGGREGATOR

# RT JARGON
ACEs
ACL
ACLs
AdminCc
AdminCcs
Bcc
Cc
Ccs
CustomField
Gecos
LastUpdated
LastUpdatedBy
Portlet
Portlets
RT's
Requestor
Requestors
crontool
lifecycle
lifecycles
mailgate
HotList
