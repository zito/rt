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
auditability
depluralization
multi
one's
pre-existing

# PROGRAMMING JARGON
add-ons
API
APIs
autohandler
canonicalizes
CGI
checkboxes
codebase
codepath
CPAN
cronjobs
datetime
DBI
denormalizes
deserializing
dhandler
dropdown
DSN
ENTRYAGGREGATOR
filename
GnuPG
GPG
hostname
html
iCalendar
inline
Intercal
keyserver
login
logins
longblob
longtext
metadata
minify
Mozilla's
MUA
MUAs
multipart
multiparts
optree
overridable
paramhash
paramhash's
passphrase
perltidy
perltidyrc
PGP
plugin's
plugins
prepopulated
rebless
reblesses
recursing
reinitializes
reparenting
resultset
RSS
runtime
SHA
SQL
startup
STDERR
STDOUT
subclause
subcomponents
subdirectory
textbox
TODO
tuple
tuples
UI
unary
unicode
uninstall
unix
unsets
username
usernames
UTF-8
variable's
workflow

# RT JARGON
ACEs
ACL
ACLs
AdminCc
AdminCcs
attribute's
autoreplies
Bcc
Cc
Ccs
crontool
CustomField
formatter
formatters
Gecos
HotList
LastUpdated
LastUpdatedBy
lifecycle
lifecycles
lookup
mailgate
portlet
portlets
Requestor
requestor
Requestors
requestors
RT's
RTx
subvalue
subvalues
wipeout
