package XAS::Collector::Connector;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;
use Params::Validate 'ARRAYREF';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Stomp::POE::Client',
  accessors => 'events',
  mutators  => 'connected',
  codec     => 'JSON',
  vars => {
    PARAMS => {
      -types  => { type => ARRAYREF },
      -alias  => { optional => 1, default => 'connector' },
    }
  }
;

#use Data::Dumper;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_message {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $data;
    my $message;
    my $session;
    my $alias = $self->alias;
    my $types = $self->types;
    my $message_id = $frame->header->message_id;
    my $nframe = $self->stomp->ack(
        -message_id => $message_id
    );

    try {

        $message = decode($frame->body);

        $self->log->info_msg('collector_received', 
            $alias, 
            $message_id, 
            $message->{type}, 
            $message->{hostname}
        );

        $data = $message->{data};
        $session = $self->_get_session($message->{type}, $types);

        if (defined($session)) {

            $poe_kernel->call($session, 'store_data', $data, $nframe);

        } else {

            $self->throw_msg(
                'xas.collector.connector.handle_message',
                'collector_unknowntype',
                $alias, $message->{type}
            );

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

}

sub connection_down {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->connected(0);

}

sub connection_up {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->connected(1);

}

sub start_queue {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $queue = $args->{'-queue'};

    if ($self->connected) {

        my $frame = $self->stomp->subscribe(
            -destination => $queue,
            -ack         => 'client'
        );

        $self->log->info_msg('collector_subscribed', $alias, $queue);
        $poe_kernel->post($alias, 'write_data', $frame);

    } else {

        $poe_kernel->delay('start_queue', 5, $args);

    }

}

sub stop_queue {
    my ($self, $args) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $queue = $args->{'-queue'};

    if ($self->connected) {

        my $frame = $self->stomp->unsubscribe(
            -destination => $queue,
        );

        $self->log->info_msg('collector_unsubscribed', $alias, $queue);
        $poe_kernel->post($alias, 'write_data', $frame);

    }

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('start_queue', $self);
    $poe_kernel->state('stop_queue',  $self);

    $self->events->subscribe($alias);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{events} = XAS::Lib::POE::PubSub->new();
    $self->{connected} = 0;

    return $self;

}

sub _get_session {
    my ($self, $wanted, $types) = @_;

    my $key;
    my $type;
    my $session;

    for $type ( @$types ) {
        for $key ( keys %$type ) {
            $session = $type->{$key} if ($key eq $wanted);
        }
    }

    return $session;

}

1;

__END__

=head1 NAME

XAS::Collector::Connector - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Collector::Connector;

  my $types = [
     { 'xas-alert', 'alert' },
  ];

  my $connector = XAS::Collector::Connector->new(
      -host     => $host,
      -port     => $port,
      -alias    => 'connector',
      -login    => 'collector',
      -passcode => 'ddc',
      -types    => $types
  );

=head1 DESCRIPTION

This module is used for monitoring queues on the message server. When messages
are received, they are then passed off to the appropriate message handler.

=head1 METHODS

=head2 new

The module inherits from L<XAS::Lib::Stomp::POE::Client|XAS::Lib::Stomp::POE::Client>
and adds these additional parameters:

=over 4 

=item B<-types>

This is a list of XAS packet types that this connector can handle. The list
consists of hashes with the following values: XAS packet type, name of 
the session handler for that packet type.

=back

=head1 PUBLIC EVENTS

=head2 handle_message(OBJECT, ARG0)

Decode the packet type and pass it off to the appropriate message handler.

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The received STOMP frame.

=back

=head2 connection_down(OBJECT)

Mark the connection to message queue server as down.

=over 4

=item B<OBJECT>

A handle to the current object.

=back

=head2 connection_up(OBJECT)

Mark the connection to message queue server as up.

=over 4

=item B<OBJECT>

A handle to the current object.

=back

=head2 stop_queue(OBJECT, ARG0)

Stop processing the specified queue.

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

A hash reference, where the memeber '-queue' contains the name of the
queue to stop procesing.

=back

=head2 start_queue(OBJECT, ARG0)

Start processing the specified queue.

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

A hash reference, where the memeber '-queue' contains the name of the
queue to start procesing.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Colletor|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
