package XAS::Apps::Collector::Process;

our $VERSION = '0.01';

use Try::Tiny;
use XAS::Collector::Connector;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::App::Service',
  mixin     => 'XAS::Lib::Mixins::Configs',
  utils     => 'dotid trim load_module',
  accessors => 'host port cfg types',
  vars => {
    SERVICE_NAME         => 'XAS_Collector',
    SERVICE_DISPLAY_NAME => 'XAS Collector',
    SERVICE_DESCRIPTION  => 'The XAS Collector',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my @sections = $self->cfg->Sections();

    foreach my $section (@sections) {

        next if ($section !~ /^collector:/);

        my ($alias) = $section =~ /^collector:(.*)/;
        my $queue   = $self->cfg->val($section, 'queue');
        my $module  = $self->cfg->val($section, 'module');
        my $type    = $self->cfg->val($section, 'packet-type');

        $alias = trim($alias);

        load_module($module);

        my $collector = $module->new(
            -alias     => $alias,
            -connector => 'connector',
            -queue     => $queue,
        );

        push(@{$self->{types}}, {
            'packet-type' => $alias
        });

        $self->service->register($alias);

    }

}

sub main {
    my $self = shift;

    $self->setup();

    my $connection = XAS::Collector::Connector->new(
        -alias           => 'connector',
        -host            => $self->host,
        -port            => $self->port,
        -tcp_keepalive   => 1,
        -retry_reconnect => 1,
        -types           => $self->types,
    );

    $self->log->info_msg('startup');

    $self->service->register('connector');
    $self->service->run();

    $self->log->info_msg('shutdown');

}

sub options {
    my $self = shift;

    $self->{port} = $self->env->mqport;
    $self->{host} = $self->env->mqserver;

    return {
        'port=s' => \$self->{port},
        'host=s' => \$self->{host},
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Collector::Process - This module will process alerts

=head1 SYNOPSIS

 use XAS::Apps::Collector::Process;

 my $app = XAS::Apps::Collector::Process->new(
     -throws => 'xas-collector',
 );

 exit $app->run();

=head1 DESCRIPTION

This module will process alerts from the message queue. It inherits from
L<XAS::Lib::App::Services|XAS::Lib::App::Services>.

=head1 CONFIGURATION

This module reads a configuration file. The default is <XAS_ROOT>/etc/<$0>.ini,
this can be overridden with the --cfgfile cli option. The configuration file 
has the following format:

    [collector: alert]
    queue = /queue/alert
    packet-type = xas-alert
    module = XAS::Messaging::Collector::Alert

This uses the standard .ini format. The entries mean the following:

    [controller: xxxx] - The beginning of the stanza.
    queue              - The message queue to listen on, defaults to '/queue/xas'.
    packet-type        - The message type expected.
    module             - The module that handles that message type.

=head1 OPTIONS

This modules provides these additonal cli options.

=head2 --host

This is the host that the message queue is on.

=head2 --port

This is the port that it listens on.

=head1 SEE ALSO

=over 4

=item sbin/xas-collector

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
