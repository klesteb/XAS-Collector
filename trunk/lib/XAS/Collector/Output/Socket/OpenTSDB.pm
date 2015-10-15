package XAS::Collector::Output::Socket::OpenTSDB;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Collector::Output::Socket::Base',
  utils     => 'trim',
  vars => {
    PARAMS => {
      -eol => { optional => 1, default => "\n" }, # really? silly java programmers
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub store_data {
    my ($self, $data, $ack, $input) = @_[OBJECT, ARG0...ARG2];

    my $alias = $self->alias;
    my $queue = $self->queue;

    $self->log->debug("$alias: entering store_data()");

    try {

        my $packet = sprintf("put %s", $data);

        $poe_kernel->call($alias, 'write_data', $packet);
#        $self->log->info_msg('send', $alias);

    } catch {

        my $ex = $_;

        $self->log->debug(Dumper($data));
        $self->exception_handler($ex);

    };

    $poe_kernel->post($input, 'write_data', $ack);
    $self->log->debug("$alias: leaving store_data()");

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Output::OpenTSDB - A class to interact with OpenTSDB

=head1 SYNOPSIS

 my $output = XAS::Collector::Output::OpenTSDB->new(
    -alias           => 'output-opentsdb',
    -port            => 4242,
    -host            => 'localhost',
    -tcp_keepalive   => 1,
    -retry_reconnect => 1.
 );

=head1 DESCRIPTION

This module will open and maintain a connection to a OpenTSDB server.

=head1 METHODS

=head2 initilize

Create an event named 'store_data'.

=head2 connection_down

An event to notify the input session that the logstash connection
is currently down.

=head2 store_data

An event to recieve a data packet and an ack. The data packet is sent
to the OpenTSDB server and the ack is sent to the input session.

=head2 read_data

Read any data from OpenTSDB. Log the input to the log file.

=head2 handle_connection

Notify the input session that the connection to OpenTSDB is up.

=head1 SEE ALSO

=over 4

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
