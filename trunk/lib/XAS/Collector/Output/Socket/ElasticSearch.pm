package XAS::Collector::Output::Socket::ElasticSearch;

our $VERSION = '1.0';

use POE;
use DateTime;
use Try::Tiny;
use File::Slurp;
use XAS::Lib::POE::PubSub;
use Search::Elasticsearch;
use DateTime::Format::Strptime;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Service',
  accessors => 'es pubsub',
  codec     => 'JSON',
  constants => 'DELIMITER',
  vars => {
    PARAMS => {
      -type             => { optional => 1, default => 'syslog' },
      -nodes            => { optional => 1, default => 'localhost:9200' },
      -cxn_pool         => { optional => 1, default => 'Static' },
      -template_name    => { optional => 1, default => 'logstash' },
      -template_file    => { optional => 1, isa => 'Badger::Filesystem::File', default => undef },
      -indices_template => { optional => 1, default => 'logstash-%Y.%m.%d' },
      -install_template => { optional => 1, default => 1 },
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

        $self->es->index(
            index => $self->_current_index($data),
            type  => $self->type,
            body  => $data,
        );

        $self->log->info_msg('collector_elastic_sent', $alias, $ack->message_id);

    } catch {

        my $ex = $_;

        $self->log->debug(Dumper($data));

        if (ref($ex) && $ex->isa('Search::Elasticsearch::Error')) {

            $self->exception_elastic($ex, $ack, $input);

        } else {

            $self->exception_handler($ex);

        }

    };

    $poe_kernel->post($input, 'write_data', $ack);

    $self->log->debug("$alias: leaving store_data()");

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('store_data', $self);

    # start listening on the queue

    $self->pubsub->publish(-event => 'resume_processing');

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leasing session_initialize()");

}

sub exception_elastic {
    my $self  = shift;
    my $ex    = shift;
    my $ack   = shift;
    my $input = shift;

    my $alias  = $self->alias;
    my $type   = lc($ex->{'type'});
    my $reason = $ex->{'text'};
    my $status = $ex->{'vars'}->{'status_code'};
    my $msg = sprintf('%s -- %s', $self->env->script, $reason);

    $self->log->error_msg('collector_elastic_error', $alias, $ack->message_id, $type, $status, $reason);

    if ($self->alerts) {

        $self->alert->send(
            -priority => 'high',
            -facitity => 'systems',
            -message  => $msg
        );

    }

    if ($status > 400) {

        $poe_kernel->call($input, 'pause_processing');

    }

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $alias = $self->alias;
    my @nodes = split(DELIMITER, $self->nodes);

    $self->{'pubsub'} = XAS::Lib::PubSub->new();

    $self->log->info_msg('collector_elastic_connect', $alias, join(',', @nodes));

    $self->{'es'} = Search::Elasticsearch->new(
        nodes    => \@nodes,
        cxn_pool => $self->cxn_pool,
    );

    $self->_es_install_template() if ($self->install_template);

    return $self;

}

sub _cvt_timestamp {
    my $self      = shift;
    my $timestamp = shift;

    my $parser = DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%dT%H:%M:%S.%N%z',
        on_error => sub {
            my ($obj, $err) = @_;
            $self->throw_msg(
                dotid($self->class) . '.baddate',
                'collector_baddate',
                $err, $timestamp
            );
        }
    );

    return $parser->parse_datetime($timestamp);

}

sub _current_index {
    my $self = shift;
    my $data = shift;

    my $now;

    if (defined($data->{'@timestamp'})) {

        $now = $self->_cvt_timestamp($data->{'@timestamp'});

    } else {

        $now = DateTime->now(time_zone => 'local');

    }

    return ($now->strftime($self->indices_template));

}

sub _template_body {
    my $self = shift;

    my $json_text;

    if (defined($self->template_file)) {

      $json_text = read_file($self->template_file->path);

    } else {

      $json_text = read_file( \*DATA );

    }

    return (decode($json_text));

}

sub _es_install_template {
    my $self = shift;

    my $alias = $self->alias;
    my $name  = $self->template_name;

    if ($self->es->indices->exists_template( name => $name )) {

        $self->log->debug("$alias: index template '$name' already in place");

    } else {

        $self->log->info_msg('collector_elastic_template', $alias, $name);

        $self->es->indices->put_template(
            name => $name,
            body => $self->_template_body,
        );

    }

}

1;

=head1 NAME

XAS::Collector::Output:::Socket::ElasticSearch - Send output to an ElasticSearch cluster

=head1 SYNOPSIS

 use XAS::Collector::Output::Socket::ElasticSearch;

 my $output = XAS::Collector::Output::Socket::ElasticSearch->new(
    -alias => 'output-elasticsearch',
 );

=head1 DESCRIPTION

This module will store data in a Elasticsearch cluster. This interface does
not implement bulk uploads. While this does slow down storage, it was felt
that acking individual messages, thus maintaining coherency with the
message queue server, was more important then speed. You can always
run more collectors listening on the same queue. 

This module emulates what Logstash does when it communicates with Elasticsearch. 

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::Service|XAS::Lib::Service> 
and takes these addtional parameters.

=over 4

=item B<-type>

This defined the document type, Defaults to 'syslog'.

=item B<-nodes>

The Elasticsearch nodes to connect too. Defaults to 'localhost:9200'.
This can be a comma delimted string for addtional nodes to use.

=item B<-cxn_pool>

The Elasticsearch connection pool. Defaults to 'Static'. Check 
L<Search::Elasticsearch|https://metacpan.org/pod/Search::Elasticsearch> for
additional options.

=item B<-template_name>

The name of the Elasticsearch template to use when storing the message.
Defaults to 'logstash'.

=item B<-template_file>

An optionl file that contains an Elasticsearch template. This must be in
JSON format.

=item B<-install_template>

Wither to install the template if it not defined, Defaults to 1.

=item B<-indices_template>

The name of the Elastic Search index, Defaults to 'logstash-%Y.%m.%d'.

=back

=head1 PUBLIC EVENTS

=head2 store_data(OBJECT, ARG0...ARG2)

This event will trigger the sending of packets to a logstash instance. 

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

=item L<XAS|XAS>

=item L<XAS::Collector|XAS::Collector>

=item L<Search::Elasticsearch|https://metacpan.org/pod/Search::Elasticsearch>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

# emulate what Logstash is doing

__DATA__
{
  "logstash" : {
    "order" : 0,
    "template" : "logstash-*",
    "settings" : {
      "index.refresh_interval" : "5s"
    },
    "mappings" : {
      "_default_" : {
        "dynamic_templates" : [ {
          "string_fields" : {
            "mapping" : {
              "index" : "analyzed",
              "omit_norms" : true,
              "type" : "string",
              "fields" : {
                "raw" : {
                  "index" : "not_analyzed",
                  "ignore_above" : 256,
                  "type" : "string"
                }
              }
            },
            "match_mapping_type" : "string",
            "match" : "*"
          }
        } ],
        "properties" : {
          "geoip" : {
            "dynamic" : true,
            "path" : "full",
            "properties" : {
              "location" : {
                "type" : "geo_point"
              }
            },
            "type" : "object"
          },
          "@version" : {
            "index" : "not_analyzed",
            "type" : "string"
          }
        },
        "_all" : {
          "enabled" : true
        }
      }
    },
    "aliases" : { }
  }
}
_
