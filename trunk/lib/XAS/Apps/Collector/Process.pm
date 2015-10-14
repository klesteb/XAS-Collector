package XAS::Apps::Collector::Process;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::App::Service',
  mixin     => 'XAS::Lib::Mixins::Configs',
  utils     => 'dotid load_module trim',
  accessors => 'cfg',
  vars => {
    SERVICE_NAME         => 'XAS_Collector',
    SERVICE_DISPLAY_NAME => 'XAS Collector',
    SERVICE_DESCRIPTION  => 'The XAS Collector'
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my @args;
    my @sections = $self->cfg->Sections();

    # formatters

    foreach my $section (@sections) {

        next if ($section =~ /^collector:\s+input/);
        next if ($section =~ /^collector:\s+output/);
        next if ($section !~ /^collector:/);

        my ($type) = $section =~ /^collector:(.*)/;

        my $module = $self->cfg->val($section, 'module');
        my $alias  = $self->cfg->val($section, 'alias');
        my $queue  = $self->cfg->val($section, 'queue');
        my $output = $self->cfg->val($section, 'output');

        $self->{'types'}->{trim($type)} = {
            queue  => $queue,
            format => $alias,
            output => $output
        };

        load_module($module);
        $module->new(-alias => $alias);

    }

    # outputers

    foreach my $section (@sections) {

        next if ($section !~ /^collector:\s+input/);
        next if ($section !~ /^collector:/);

        @args = ();

        my $module = $self->cfg->val($section, 'module');
        my $alias  = $self->cfg->val($section, 'alias');

        push(@args, '-types', $self->{'types'});

        my @parameters = $self->cfg->Parameters($section);

        foreach my $parameter (@parameters) {

            next if ($parameter eq 'module');

            push(@args, "-$parameter", $self->cfg->val($section, $parameter));

        }

        load_module($module);
        $module->new(@args);

        $self->service->register($alias);

    }

    # inputers

    foreach my $section (@sections) {

        next if ($section !~ /^collector:\s+output/);
        next if ($section !~ /^collector:/);

        @args = ();

        my $module = $self->cfg->val($section, 'module');
        my $alias  = $self->cfg->val($section, 'alias');

        my @parameters = $self->cfg->Parameters($section);

        foreach my $parameter (@parameters) {

            next if ($parameter eq 'module');

            push(@args, "-$parameter", $self->cfg->val($section, $parameter));

        }

        load_module($module);
        $module->new(@args);

        $self->service->register($alias);

    }

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->info_msg('startup');

    $self->service->run();

    $self->log->info_msg('shutdown');

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

# [collector: input]
# module = XAS::Collector::Input::Stomp
# port = 61613
# host = localhost
# alias = input-stomp
#
# [collector: output]
# module = XAS::Collector::Output::Logstash
# port = 9500
# host = localhost
# alias = output-logstash
#
# [collector: xas-alerts]
# formatter = XAS::Collector::Formatter::Alerts
# alias = wpm-notify
# queue = /queue/alerts
# output = output-logstash
#

__END__

=head1 NAME

XAS::Apps::Collector::Alerts - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Collector::Alerts;

 my $app = XAS::Apps::Collector::Alerts->new();

 $app->run();

=head1 DESCRIPTION

This module will retrieve 'xas-alerts' packets from the message queue,
convert the format to a logstash 'json_event' and forward it to logstash
for storage in Elasticsearch.

=head1 METHODS

=head2 setup

=head2 main

=head2 options

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
