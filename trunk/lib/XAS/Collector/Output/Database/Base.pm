package XAS::Collector::Output::Database::Base;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Model::Schema;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  utils     => 'db2dt',
  accessors => 'schema event',
  vars => {
    PARAMS => {
      -database => { optional => 1, default => 'messaging' },
    }
  }
;

#use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

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
        -event => 'resume_processing',
        -args  => { 
            '-queue' => $queue 
        }
    );

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leasing session_startup()");

}

# --------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{event}  = XAS::Lib::POE::PubSub->new();
    $self->{schema} = XAS::Model::Schema->opendb($self->database);

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
