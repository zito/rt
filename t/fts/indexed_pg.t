
use strict;
use warnings;

use RT::Test tests => undef;
plan skip_all => 'Not Pg' unless RT->Config->Get('DatabaseType') eq 'Pg';

my ($major, $minor) = $RT::Handle->dbh->get_info(18) =~ /^0*(\d+)\.0*(\d+)/;
plan skip_all => "Need Pg 8.2 or higher; we have $major.$minor"
    if "$major.$minor" < 8.2;

plan tests => 21;

RT->Config->Set( FullTextSearch => Enable => 1, Indexed => 1, Column => 'ContentIndex', Table => 'Attachments' );

setup_indexing();

my $q = RT::Test->load_or_create_queue( Name => 'General' );
ok $q && $q->id, 'loaded or created queue';
my $queue = $q->Name;

sub setup_indexing {
    my %args = (
        'no-ask'       => 1,
        command        => $RT::SbinPath .'/rt-setup-fulltext-index',
        dba            => $ENV{'RT_DBA_USER'},
        'dba-password' => $ENV{'RT_DBA_PASSWORD'},
    );
    my ($exit_code, $output) = RT::Test->run_and_capture( %args );
    ok(!$exit_code, "setted up index") or diag "output: $output";
}

sub sync_index {
    my %args = (
        command => $RT::SbinPath .'/rt-fulltext-indexer',
    );
    my ($exit_code, $output) = RT::Test->run_and_capture( %args );
    ok(!$exit_code, "setted up index") or diag "output: $output";
}

sub run_tests {
    my @test = @_;
    while ( my ($query, $checks) = splice @test, 0, 2 ) {
        run_test( $query, %$checks );
    }
}

my @tickets;
sub run_test {
    my ($query, %checks) = @_;
    my $query_prefix = join ' OR ', map 'id = '. $_->id, @tickets;

    my $tix = RT::Tickets->new(RT->SystemUser);
    $tix->FromSQL( "( $query_prefix ) AND ( $query )" );

    my $error = 0;

    my $count = 0;
    $count++ foreach grep $_, values %checks;
    is($tix->Count, $count, "found correct number of ticket(s) by '$query'") or $error = 1;

    my $good_tickets = ($tix->Count == $count);
    while ( my $ticket = $tix->Next ) {
        next if $checks{ $ticket->id };
        diag $ticket->Subject ." ticket has been found when it's not expected";
        $good_tickets = 0;
    }
    ok( $good_tickets, "all tickets are good with '$query'" ) or $error = 1;

    diag "Wrong SQL query for '$query':". $tix->BuildSelectQuery if $error;
}

@tickets = RT::Test->create_tickets(
    { Queue => $q->id },
    { Subject => 'fts test 1', Content => 'book' },
    { Subject => 'fts test 2', Content => 'bars'  },
);
sync_index();

my $book = $tickets[0];
my $bars = $tickets[1];

run_tests(
    "Content LIKE 'book'" => { $book->id => 1, $bars->id => 0 },
    "Content LIKE 'bars'" => { $book->id => 0, $bars->id => 1 },

    # make sure that Pg stemming works
    "Content LIKE 'books'" => { $book->id => 1, $bars->id => 0 },
    "Content LIKE 'bar'"   => { $book->id => 0, $bars->id => 1 },

    # no matches
    "Content LIKE 'baby'" => { $book->id => 0, $bars->id => 0 },
    "Content LIKE 'pubs'" => { $book->id => 0, $bars->id => 0 },
);

@tickets = ();
