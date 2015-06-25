package XAS::Collector;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

XAS::Collector - A set of procedures and modules to retrieve messages and store them

=head1 DESCRIPTION

These modules are used to collect messages from a STOMP based message queue
server. The messages are then parsed and forwarded to an appropiate
datastore.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<XAS::Collector::Connector|XAS::Collector::Connector>

=item L<XAS::Collector::Alerts::Database|XAS::Collector::Alerts::Database>

=item L<XAS::Collector::Alerts::Logstash|XAS::Collector::Alerts::Logstash>

=item L<XAS::Collector::Logs::Database|XAS::Collector::Logs::Database>

=item L<XAS::Collector::Logs::Logstash|XAS::Collector::Logs::Logstash>

=item L<XAS::Model::Database::Messaging::Result::Alert|XAS::Model::Database::Messaging::Alert>

=item L<XAS::Model::Database::Messaging::Result::Log|XAS::Model::Database::Messaging::Result::Log>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
