use strict;
use warnings;
use RT::Test tests => undef;
BEGIN {
    plan skip_all => 'Email::Abstract and Test::Email required.'
        unless eval { require Email::Abstract; require Test::Email; 1 };
    plan 'no_plan';
}

RT::Test->switch_templates_ok('html');

use RT::Test::Email;

my $root = RT::User->new(RT->SystemUser);
$root->Load('root');

# Set root as admincc
my $q = RT::Queue->new(RT->SystemUser);
$q->Load('General');
my ($ok, $msg) = $q->AddWatcher( Type => 'AdminCc', PrincipalId => $root->Id );
ok($ok, "Added root as a watcher on the General queue");

# Create a couple users to test notifications
my %users;
for my $user_name (qw(enduser tech)) {
    my $user = $users{$user_name} = RT::User->new(RT->SystemUser);
    $user->Create( Name => ucfirst($user_name),
                   Privileged => 1,
                   EmailAddress => $user_name.'@example.com');
    my ($val, $msg);
    ($val, $msg) = $user->PrincipalObj->GrantRight(Object =>$q, Right => $_)
        for qw(ModifyTicket OwnTicket ShowTicket);
}

my $t = RT::Ticket->new(RT->SystemUser);
my ($tid, $ttrans, $tmsg);

diag "Autoreply and AdminCc (Transaction)";
mail_ok {
    ($tid, $ttrans, $tmsg) = 
        $t->Create(Subject => "The internet is broken",
                   Owner => 'Tech', Requestor => 'Enduser',
                   Queue => 'General');
} { from    => qr/The default queue/,
    to      => 'enduser@example.com',
    subject => qr/\Q[example.com #1] AutoReply: The internet is broken\E/,
    body    => parts_regex(
        'trouble ticket regarding The internet is broken',
        'trouble ticket regarding <b>The internet is broken</b>'
    ),
    'Content-Type' => qr{multipart},
},{ from    => qr/RT System/,
    bcc     => 'root@localhost',
    subject => qr/\Q[example.com #1] The internet is broken\E/,
    body    => parts_regex(
        'Request 1 \(http://localhost:\d+/Ticket/Display\.html\?id=1\)\s+?was acted upon by RT_System',
        'Request <a href="http://localhost:\d+/Ticket/Display\.html\?id=1">1</a> was acted upon by RT_System\.</b>'
    ),
    'Content-Type' => qr{multipart},
};


diag "Autoreply and AdminCc (Transaction)";
mail_ok {
    ($ok, $tmsg) = $t->Correspond(
        Content => 'This is a test of correspondence using HTML templates.',
    );
} { from    => qr/RT System/,
    bcc     => 'root@localhost',
    subject => qr/\Q[example.com #1] The internet is broken\E/,
    body    => parts_regex(
        'Ticket URL: http://localhost:\d+/Ticket/Display\.html\?id=1.+?'.
        'This is a test of correspondence using HTML templates\.',
        'Ticket URL: <a href="(http://localhost:\d+/Ticket/Display\.html\?id=1)">\1</a>.+?'.
        '<pre>This is a test of correspondence using HTML templates\.</pre>'
    ),
    'Content-Type' => qr{multipart},
},{ from    => qr/RT System/,
    to      => 'enduser@example.com',
    subject => qr/\Q[example.com #1] The internet is broken\E/,
    body    => parts_regex(
        'This is a test of correspondence using HTML templates\.',
        '<pre>This is a test of correspondence using HTML templates\.</pre>'
    ),
    'Content-Type' => qr{multipart},
};

sub parts_regex {
    my ($text, $html) = @_;

    my $pattern = 'Content-Type: text/plain.+?' . $text . '.+?' .
                  'Content-Type: text/html.+?'  . $html;

    return qr/$pattern/s;
}

