package XAS::Collector::Formatter::Alerts;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Collector::Formatter::Base',
  utils   => 'db2dt',
;

#use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

sub format_data {
    my ($self, $data, $ack, $input, $output) = @_[OBJECT,ARG0...ARG3];

    my $alias  = $self->alias;

    $self->log->debug("$alias: formatter");

    my $dt = db2dt($data->{'datetime'});
    my $message = sprintf('[%s] %s - %s - %s - %s',
        $data->{'datetime'}, $data->{'hostname'}, $data->{'facility'},
        $data->{'priority'}, $data->{'message'}
    );

    my $rec = {
        datetime   => $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
        hostname   => $data->{'hostname'},
        level      => $data->{'priority'},
        facility   => $data->{'facility'},
        process    => $data->{'process'},
        message    => $data->{'message'},
        pid        => $data->{'pid'},
        tid        => $data->{'tid'},
        msgnum     => $data->{'msgnum'},
    };

    $poe_kernel->call($output, 'store_data', $rec, $ack, $input);

}

# --------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Alerts::Database - Perl extension for the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Connector;
  use XAS::Collector::Alerts::Database;

  main: {

      my $types = [
          {'xas-alert', 'alert'}
      ];

      my $connector = XAS::Collector::Connector->new(
          -alias         => 'connector',
          -host          => $host,
          -port          => $port,
          -tcp_keepalive => 1,
          -login         => 'guest',
          -passcode      => 'guest',
          -types         => $types
      );

      my $notify = XAS::Collector::Alerts::Database->new(
          -alias     => 'alert',
          -connector => 'connector',
          -queue     => '/queue/alerts',
      );

      $poe_kernel->run();

      exit 0;

  }

=head1 DESCRIPTION

This module handles the xas-alert packet type.

=head1 METHODS

=head2 new

This module inheirts from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and
takes these additional parameters:

=over 4

=item B<-connector>

The name of the connector session.

=item B<-queue>

The name of the queue to process messages from.

=item B<-database>

An optional configuration name for the database to use, defaults to 'messaging'.

=back

=head1 PUBLIC EVENTS

=head2 store_data(OBJECT, ARG0, ARG1)

This event will trigger the storage of xas-alert packets into the database. 

=over 4

=item B<OBJECT>

A handle to the current object.

=item B<ARG0>

The data to be stored within the database.

=item B<ARG1>

The acknowledgement to send back to the message queue server.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Collector|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
