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

# Autoreply and AdminCc (Transaction)
mail_ok {
    ($tid, $ttrans, $tmsg) = 
        $t->Create(Subject => "The internet is broken",
                   Owner => 'Tech', Requestor => 'Enduser',
                   Queue => 'General');
} { from    => qr/The default queue/,
    to      => 'enduser@example.com',
    subject => qr/\Q[example.com #1] AutoReply: The internet is broken\E/,
    body    => qr{
        Content-Type:\stext/plain.+?
        trouble\sticket\sregarding\sThe\sinternet\sis\sbroken.+?
        Content-Type:\stext/html.+?
        trouble\sticket\sregarding\s<b>The\sinternet\sis\sbroken</b>
    }xs,
    'Content-Type' => qr{multipart},
},{ from    => qr/RT System/,
    bcc     => 'root@localhost',
    subject => qr/\Q[example.com #1] The internet is broken\E/,
    body    => qr{
        Content-Type:\stext/plain.+?
        Request\s1\s\(http://localhost:\d+/Ticket/Display\.html\?id=1\)\s+was\sacted\supon\sby\sRT_System.+?
        Content-Type:\stext/html.+?
        Request\s<a\shref="http://localhost:\d+/Ticket/Display\.html\?id=1">1</a>\swas\sacted\supon\sby\sRT_System\.</b>
    }xs,
    'Content-Type' => qr{multipart},
};


