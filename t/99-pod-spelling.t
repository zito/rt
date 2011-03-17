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
Ruslan
Zakirov
