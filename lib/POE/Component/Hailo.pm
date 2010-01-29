package POE::Component::Hailo;

use strict;
use warnings;
use Carp;
use POE;
use POE::Component::Generic;

our $VERSION = '0.01';

sub spawn {
    my ($package, %args) = @_;
    my $self = bless \%args, $package;
    $self->{response} = {
        learn       => 'hailo_learned',
        train       => 'hailo_trained',
        reply       => 'hailo_replied',
        learn_reply => 'hailo_learn_replied',
    };
    
    POE::Session->create(
        object_states => [
            $self => [qw(_start _result shutdown _sig_DIE)],
            $self => {
                learn       => '_method_wrapper',
                train       => '_method_wrapper',
                reply       => '_method_wrapper',
                learn_reply => '_method_wrapper',
            },
        ],
    );

    return $self;
}

sub _start {
    my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];
    $self->{session_id} = $session->ID();
    
    $kernel->sig(DIE => '_sig_DIE');

    if ($self->{alias}) {
        $poe_kernel->alias_set($self->{alias});
    }
    else {
        $poe_kernel->refcount_increment($self->{session_id}, __PACKAGE__);
    }

    $self->{hailo} = POE::Component::Generic->spawn(
        package        => 'Hailo',
        object_options => [ %{ $self->{Hailo_args} || { }} ],
        methods        => [ qw(learn train reply learn_reply) ],
        verbose        => 1,
    );
  
    return;
}

sub _sig_DIE {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};
    warn "Error: Event $ex->{event} in $ex->{dest_session} raised exception:\n";
    warn "  $ex->{error_str}\n";
    $kernel->sig_handled();
    return;
}

sub shutdown {
    my $self = $_[OBJECT];

    $self->{hailo}->shutdown();

    if (defined $self->{alias}) {
        $poe_kernel->alias_remove($self->{alias});
    }
    else {
        $poe_kernel->refcount_decrement($self->{session_id}, __PACKAGE__);
    }
    return;
}

sub _method_wrapper {
    my ($self, $sender, $event, $args, $context)
        = @_[OBJECT, SENDER, STATE, ARG0, ARG1];

    $context = {
        user_context => $context,
        response     => $self->{response}{$event},
    };
    
    $self->{hailo}->yield(
        $event =>
            {
                event => '_result',
                data => {
                    recipient => $sender->ID(),
                    context   => $context,
                },
            },
            @$args,
    );
    return;
}

sub _result {
    my ($ref, @results) = @_[ARG0..$#_];

    if ($ref->{error}) {
        # do something?
    }
    
    my ($recipient, $context) = @{ $ref->{data} }{qw(recipient context)};
    $poe_kernel->post(
        $recipient,
        $context->{response},
        \@results,
        $context->{user_context}
    );
    
    return;
}

sub session_id {
    my ($self) = @_;
    return $self->{session_id};
}

1;
__END__

=head1 NAME

POE::Component::Hailo - A non-blocking wrapper around L<Hailo|Hailo>

=head1 SYNOPSIS

 use POE;
 use POE::Component::Hailo;

 POE::Session->create(
     package_states => [
         main => [ qw(_start learned replied) ],
     ],
 );

 $poe_kernel->run();

 sub _start {
     my $heap = $_[HEAP];
     $heap->{hailo} = POE::Component::Hailo->spawn(
         alias      => 'hailo',
         Hailo_args => {
             order          => 5,
             storage_class  => 'SQLite',
             brain_resource => 'hailo.sqlite',
         },
     );
     
     $poe_kernel->post(hailo => learn => 'This is a sentence');
 }

 sub learned {
     my $error = $_[ARG0];
     print "Learned" if !defined $error;
 }
 
 sub replied {
     my $reply = $_[ARG0];
     die "Didn't get a reply" if !defined $reply;
     print "Got reply: $reply\n";
 }

=head1 DESCRIPTION

POE::Component::Hailo is a L<POE|POE> component that provides a
non-blocking wrapper around L<Hailo|Hailo>. It accepts the events listed
under L</INPUT> and emits the events listed under L</OUTPUT>.

=head1 METHODS

=head2 C<spawn>

This is the constructor. It takes the following arguments:

B<'alias'>, an optional alias for the component's session.

B<'Hailo_args'>, a hash reference of arguments to pass to L<Hailo|Hailo>'s
constructor.

=head1 METHODS

=head2 C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=head1 INPUT

The POE events this component will accept.

=head2 C<learn>

=head2 C<train>

=head2 C<reply>

=head2 C<learn_reply>

All these events take two arguments. The first is an array reference of
arguments which will be passed to the L<Hailo|Hailo> method of the same
name. The second (optional) is a hash reference You'll get this hash
reference back with corresponding event listen under L</OUTPUT>.

=head2 C<shutdown>

Takes no arguments. Terminates the component.

=head1 OUTPUT

The component will post these events to your session.

=head2 C<hailo_learned>

=head2 C<hailo_trained>

=head2 C<hailo_replied>

=head2 C<hailo_learn_replied>

ARG0 is an array reference of arguments returned by the underlying
L<Hailo|Hailo> method. ARG1 is the context hashref you provided (if any).

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
