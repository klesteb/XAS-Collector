package XAS::Collector::Logs::Logstash;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::POE::Client',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  accessors => 'events',
  codec     => 'JSON',
  vars => {
    PARAMS => {
      -connector => 1,
      -queue     => 1,
      -eol       => { optional => 1, default => "\n" }, # really? silly ruby programmers
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub handle_connection {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: handle_connection()");

    if ($self->tcp_keepalive) {

        $self->log->info("$alias: tcp_keepalive enabled");

        $self->init_keepalive(-tcp_keepidle => 100);
        $self->enable_keepalive($self->socket);

    }

    $self->log->info_msg('connected', $alias, $self->host, $self->port);
    $poe_kernel->post($alias, 'connection_up');

}

sub read_data {
    my ($self, $data) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->warn("$alias: $data");

}

sub store_data {
    my ($self, $data, $ack) = @_[OBJECT, ARG0, ARG1];

    my $alias = $self->alias;
    my $connector = $self->connector;

    $self->log->debug("$alias: entering store_data()");
    $self->log->debug("$alias: data type is " . ref($data));

    try {

        my $packet = encode($data);

        $self->log->info_msg('send', $alias);
        $poe_kernel->call($alias, 'write_data', $packet);

    } catch {

        my $ex = $_;

#        $self->log->debug(Dumper($data));
        $self->exception_handler($ex);

    };

    $poe_kernel->post($connector, 'write_data', $ack);

    $self->log->debug("$alias: leaving store_data()");

}

sub connection_down {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;
    my $queue = $self->queue;

    $self->log->warn_msg('down', $alias);

    $self->events->publish(
        -event => 'stop_queue',
        -args  => { 
            '-queue' => $queue 
        }
    );

}

sub connection_up {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;
    my $queue = $self->queue;

    $self->log->warn_msg('up', $alias);

    $self->events->publish(
        -event => 'start_queue',
        -args  => { 
            '-queue' => $queue 
        }
    );

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

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{events} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Collector::Logs::Logstash - Send output to a logstash server

=head1 SYNOPSIS

 use XAS::Collector::Logs::Logstash;
 
 my $output = XAS::Collector::Logs::Logstash->new(
    -alias           => 'output-logstash',
    -port            => 9500,
    -host            => 'localhost',
    -input           => 'stomp',
    -tcp_keepalive   => 1,
    -retry_reconnect => 1.
 );
 
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

=item L<XAS::Collector|XAS::Collector>

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
