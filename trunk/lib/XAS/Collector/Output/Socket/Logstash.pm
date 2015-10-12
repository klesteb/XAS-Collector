package XAS::Collector::Output::Socket::Logstash;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Collector::Output::Socket::Base',
  codec   => 'JSON',
  vars => {
    PARAMS => {
      -eol => { optional => 1, default => "\n" }, # really? silly ruby programmers
    }
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub store_data {
    my ($self, $data, $ack, $input) = @_[OBJECT, ARG0, ARG1, ARG2];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering store_data()");
    $self->log->debug("$alias: data type is " . ref($data));

    try {

        my $packet = encode($data);

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

XAS::Collector::Output:::Logstash - Send output to a logstash server

=head1 SYNOPSIS

 use XAS::Collector::Output::Logstash;

 my $output = XAS::Collector::Output::Logstash->new(
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

=item L<XAS|XAS>

=item L<XAS::Collector>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
