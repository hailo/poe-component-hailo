use strict;
use warnings;
use POE;
use POE::Component::Hailo;

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(_start replied)],
    ],
);

POE::Kernel->run();

sub _start {
    my $kernel = $_[KERNEL];
    my $hailo = POE::Component::Hailo->new(
        alias      => 'hailo',
        Hailo_args => {
            brain_resource => '/tmp/brain',
        },
    );

    $kernel->post(hailo => reply => 'how');
}

sub replied {
    my $reply = $_[ARG0];
    print $reply, "\n";
}
