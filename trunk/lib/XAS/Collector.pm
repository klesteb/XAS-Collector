package XAS::Collector;

use strict;
use warnings;

our $VERSION = '0.03';

1;

__END__

=head1 NAME

XAS::Collector - A set of procedures and modules to retrieve messages and store the results

=head1 SYNOPSIS

 use POE;
 use XAS::Collector::Input::Stomp;
 use XAS::Collector::Format::Logs;
 use XAS::Collector::Output::Database::Logs;
	
 main: {
	
    my $types => {
       'xas-logs' => {
           queue  => '/queue/logs',
           format => 'format-logs',
           output => 'database-logs',
        },
    };
	
    my $processor = XAS::Collector::Input::Stomp->new(
        -alias => 'input-stomp',
        -types => $types
    );
	
    my $formatter = XAS::Collector::Format::Logs->new(
        -alias => 'format-logs',
    );
	
    my $output = XAS::Collector::Output::Database::Logs->new(
        -alias    => 'database-logs',
        -database => 'messaging',
        -queue    => '/queue/logs',
    );
	
    $poe_kernel->run();
	
    exit 0;
	
 }

=head1 DESCRIPTION

These modules are used to collect messages from a STOMP based message queue
server. The messages are then parsed and forwarded to an appropiate
datastore.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=item L<XAS::Apps::Collector::Process|XAS::Apps::Collector::Process>

=item L<XAS::Collector::Format::Base|XAS::Collector::Format::Base>

=item L<XAS::Collector::Format::Alerts|XAS::Collector::Format::Alerts>

=item L<XAS::Collector::Format::Logs|XAS::Collector::Format::Logs>

=item L<XAS::Collector::Input::Stomp|XAS::Collector::Input::Stomp>

=item L<XAS::Collector::Output::Console::Base|XAS::Collector::Output::Console::Base>

=item L<XAS::Collector::Output::Console::Alerts|XAS::Collector::Output::Console::Alerts>

=item L<XAS::Collector::Output::Console::Logs|XAS::Collector::Output::Console::Logs>

=item L<XAS::Collector::Output::Database::Base|XAS::Collector::Output::Database::Base>

=item L<XAS::Collector::Output::Database::Alerts|XAS::Collector::Output::Database::Alerts>

=item L<XAS::Collector::Output::Database::Logs|XAS::Collector::Output::Database::Logs>

=item L<XAS::Collector::Output::Socket::Base|XAS::Collector::Output::Socket::Base>

=item L<XAS::Collector::Output::Socket::Logstash|XAS::Collector::Output::Socket::Logstash>

=item L<XAS::Collector::Output::Socket::OpenTSDB|XAS::Collector::Output::Socket::OpenTSDB>

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
