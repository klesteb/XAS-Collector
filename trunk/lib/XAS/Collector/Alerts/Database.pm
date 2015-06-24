package XAS::Collector::Alerts::Database;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use XAS::Model::Schema;
use XAS::Lib::POE::PubSub;

use XAS::Model::Database
  schema => 'XAS::Model::Database::Messaging',
  table  => 'Alert'
;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  utils     => 'db2dt',
  accessors => 'schema events',
  vars => {
    PARAMS => {
      -connector => 1,
      -queue     => 1,
    }
  }
;

#use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

sub store_data {
    my ($kernel, $self, $data, $ack) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $buffer;
    my $alias = $self->alias;
    my $schema = $self->schema;
    my $connector = $self->connector;

    $self->log->debug("$alias: entering store_data()");

    $buffer = sprintf("%s: hostname = %s; timestamp = %s; priority = %s; facility = %s; message = %s",
        $alias, $data->{hostname}, $data->{datetime}, $data->{priority}, 
        $data->{facility}, $data->{message}
    );

    $self->log->debug($buffer);

    try {

        my $rec = $self->format_data($data);

        Alerts->create_record($schema, $rec);

        $self->log->info_msg('processed', $alias, 1, $data->{hostname}, $data->{datetime});

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

    $poe_kernel->post($connector, 'send_data', $ack);

    $self->log->debug("$alias: leaving store_notify()");

}

# --------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('store_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leasing session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;
    my $queue = $self->queue;

    $self->log->debug("$alias: entering session_startup()");

    $self->events->publish(
        -event => 'start_queue',
        -args  => { 
            '-queue' => $queue 
        }
    );

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leasing session_startup()");

}

sub format_data {
    my $self = shift;
    my ($data) = $self->validate_params(\@_, [1]);

    my $alias  = $self->alias;

    $self->log->debug("$alias: formatter");

    my $dt = db2dt($data->{datetime});
    my $message = sprintf('[%s] %s - %s - %s - %s',
        $data->{datetime}, $data->{hostname}, $data->{facility},
        $data->{priority}, $data->{message}
    );

    my $rec = {
        datetime   => $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
        hostname   => $data->{hostname},
        level      => $data->{priority},
        facility   => $data->{facility},
        process    => $data->{process},
        message    => $data->{message},
        pid        => $data->{pid},
        tid        => $data->{tid},
        msgnum     => $data->{msgnum},
        revisison  => 1,
    };

    return $rec;

}

# --------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{events} = XAS::Lib::POE::PubSub->new();
    $self->{schema} = XAS::Model::Schema->opendb('messaging');

    return $self;

}

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

      XAS::Collector::Connector->new(
          RemoteAddress   => $host,
          RemotePort      => $port,
          EnableKeepAlive => 1,
          Alias           => 'collector',
          Login           => 'xas',
          Passcode        => 'xas',
          Queue           => '/queue/alerts',
          Types           => $types
      );

      my $notify = XAS::Collector::Alerts::Database->new(
          -alias     => 'alert',
          -connector => 'connector'
      );

      $poe_kernel->run();

      exit 0;

  }

=head1 DESCRIPTION

This module handles the xas-alert packet type.

=head1 PUBLIC EVENTS

=head2 store_data($kernel, $self, $data, $ack)

This event will trigger the storage of xas-alert packets into the database. 

=over 4

=item B<$kernel>

A handle to the POE environment.

=item B<$self>

A handle to the current object.

=item B<$data>

The data to be stored within the database.

=item B<$ack>

The acknowledgement to send back to the message queue server.

=back

=head1 SEE ALSO

=over 4

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
