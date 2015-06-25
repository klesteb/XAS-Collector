#!perl

use Test::More tests => 10;

BEGIN {
    use_ok( 'XAS::Apps::Collector::Process' )            || print "Bail out!\n";
    use_ok( 'XAS::Collector::Alerts::Database' )         || print "Bail out!\n";
    use_ok( 'XAS::Collector::Alerts::Logstash' )         || print "Bail out!\n";
    use_ok( 'XAS::Collector::Logs::Database' )           || print "Bail out!\n";
    use_ok( 'XAS::Collector::Logs::Logstash' )           || print "Bail out!\n";
    use_ok( 'XAS::Collector::Connector' )                || print "Bail out!\n";
    use_ok( 'XAS::Docs::Collector::Installation' )       || print "Bail out!\n";
    use_ok( 'XAS::Model::Database::Messaging::Result::Alert' ) || print "Bail out!\n";
    use_ok( 'XAS::Model::Database::Messaging::Result::Log' )   || print "Bail out!\n";
    use_ok( 'XAS::Collector' )                           || print "Bail out!\n";
}

diag( "Testing XAS Collector $XAS::Collector::VERSION, Perl $], $^X" );
