package XAS::Collector::Output::Socket::Base;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Stomp::POE::Client',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  accessors => 'event',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub handle_connection {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: handle_connection()");

    if ($self->tcp_keepalive) {

        $self->log->debug("$alias: tcp_keepalive enabled");

        $self->init_keepalive(
            -tcp_keepidle => 100,
        );

        $self->enable_keepalive($self->socket);

    }

    $self->log->info_msg('collector_connected', $alias, $self->host, $self->port);

    $self->event->publish(-event => 'resume_processing');

}

sub read_data {
    my ($self, $data) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->warn("$alias: $data");

}

sub connection_down {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->warn_msg('collector_down', $alias);

    $self->event->publish(-event => 'pause_processing');

}

sub connection_up {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->warn_msg('collector_up', $alias);

    $self->event->publish(-event => 'resume_processing');

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('store_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leasing session_initialize()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown");

    $poe_kernel->alarm_remove_all();

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{event} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Collector::Output:::Base - Send output to a logstash server

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Collector::Output::Base
 ;

=head1 DESCRIPTION

This module will open and maintain a connection to a logstash server.

=head1 METHODS

=head2 initilize

Create an event named 'store_data'.

=head2 connection_down

An event to notify the input session that the logstash connection
is currently down.

=head2 store_data

An event to recieve a data packet and an ack. The data packet is sent
to the logstash server and the ack is sent to the input session.

=head2 read_data

Read any data from logstash. Log the input to the log file.

=head2 handle_connection

Notify the input session that the connection to logstash is up.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<XAS::Collector>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
