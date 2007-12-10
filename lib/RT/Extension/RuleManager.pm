package RT::Extension::RuleManager;
use strict;
use warnings;
use RT::Template;
use YAML::Syck '1.00';
use constant RuleManagerTemplate => 'Rule Manager Template';
use constant RuleClass => 'RT::Extension::RuleManager::Rule';

sub create {
    my $self = shift;
    my %args = @_;
    my $rec = bless {
        map {
            $_ => defined $args{$_} ? $args{$_} : ''
        } RT::Extension::RuleManager::Rule::Fields()
    } => RuleClass;

    my $rules = $self->rules;
    $rec->{_root} = $rules;
    $rec->{_pos} = 0+@$rules;
    push @$rules, $rec;
    $self->_save($rules);

    return $rec;
}

sub load {
    my $self  = shift;
    my $id    = shift;
    my $rules = $self->rules;
    return undef if $id <= 0 or $id > @$rules;
    return $rules->[$id-1];
}

sub raise {
    my $self  = shift;
    my $id    = shift;
    my $rules = $self->rules;
    return undef if $id <= 1 or $id > @$rules;
    @{$rules}[$id-1, $id-2] = @{$rules}[$id-2, $id-1];
    $rules->[$id-1]{_pos} = $id-1;
    $rules->[$id-2]{_pos} = $id-2;
    return $id;
}

sub named {
    my $self = shift;
    my $name = shift;
    foreach my $rule (@{$self->rules}) {
        return $rule if $rule->Name eq $name;
    }
    return undef;
}

sub rules {
    my $self = shift;
    my $rules = $self->_load || [];
    for my $i (0..$#$rules) {
        $rules->[$i]{_pos} = $i;
        $rules->[$i]{_root} = $rules;
        bless $rules->[$i] => RuleClass;
    }
    return $rules;
}

sub _load {
    my $self = shift;
    return Load($self->_template->Content);
}

sub _save {
    my $self = shift;
    my $rules = shift;
    my @to_save;
    foreach my $rule (@$rules) {
        my %this = %$rule;
        delete $this{_pos};
        delete $this{_root};
        push @to_save, \%this;
    }
    return $self->_template->SetContent(Dump(\@to_save));
}

# Find our own, special RT::Template.  If one does not exist, create it.
sub _template {
    my $self = shift;
    my $template = RT::Template->new($RT::SystemUser);
    $template->Load(RuleManagerTemplate);
    if (!$template->Id) {
        $template->Create(
            Name        => RuleManagerTemplate,
            Description => RuleManagerTemplate,
            Content     => "--- []\n",
            Queue       => 0,
        );
    }
    return $template;
}

package RT::Extension::RuleManager::Rule;

use constant Fields => qw( Name Field Pattern Handler Argument );

sub id { $_[0]{_pos}+1 }
sub Id { $_[0]{_pos}+1 }

sub UpdateRecordObject {
    my $self = shift;
    my $args = shift;
    my $updated;
    foreach my $field (Fields) {
        exists $args->{$field} or next;
        $updated = 1;
        $self->{$field} = $args->{$field};
    }
    RT::Extension::RuleManager->_save($self->{_root}) if $updated;
}

BEGIN {
    no strict 'refs';
    no warnings 'uninitialized';
    eval join '', map {qq[
        sub $_ { \$_[0]{'$_'} }
        sub Set$_ {
            return if \$_[0]{'$_'} eq \$_[1];
            \$_[0]{'$_'} = \$_[1];
            RT::Extension::RuleManager->_save(\$_[0]{_root});
        }
    ]} Fields;
}

1;
