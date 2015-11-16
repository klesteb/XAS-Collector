package XAS::Collector::Output::Socket::OpenTSDB;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Collector::Output::Socket::Base',
  utils   => 'trim',
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

XAS::Collector::Output::Socket::OpenTSDB - A class to interact with OpenTSDB

=head1 SYNOPSIS

  use XAS::Collector::Output::Socket::OpenTSDB;

  my $output = XAS::Collector::Output::Socket::OpenTSDB->new(
      -alias => 'output-opentsdb',
      -queue => '/queue/nmon',
  );

=head1 DESCRIPTION

This module will open and maintain a connection to a OpenTSDB server.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Collector::Output::Socket::Base|XAS::Collector::Output::Socket::Base> 
and takes the same parameters.

=head1 PUBLIC EVENTS

=head2 store_data(OBJECT, ARG0, ARG1, ARG2)

This event will trigger the sending of packets to a opentsdb instance. 

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The data to be stored within the database.

=item B<ARG1>

The acknowledgement to send back to the message queue server.

=item B<ARG2>

The input to return the ack too.

=back

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
