package XAS::Collector;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

XAS::Collector - A set of procedures and modules to interact with message queues

=head1 DESCRIPTION

These modules are used to collect messages from a STOMP based message queue
server. These messages are then parsed and forwarded to a Logstash instance.
From there, Logstash can forward them to a final distntation. In my case, that 
is Elasticsearch. 

These modules only support the self generated Alerts and the direct logging 
to the Logstash spooling process. Both of them use the same Logstash JSON 
Event format. Which makes viewing the entries with Kibana easier. 

You may be wondering why these modules are needed. Logstash does have a STOMP
connector, which I could never get to work. These modules use the raw TCP/IP 
port connector, which has it own set of problems. One of which is, if 
Elasticsearch goes into a cluster transition, you may lose data, as Logstash
doesn't appear to handle that very well.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XAS
    perldoc XAS::Collector

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
