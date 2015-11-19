XAS Collector - A data collector for the XAS Environment
=========================================================

XAS is a set of modules, procedures and practices to help write
consistent Perl5 code for an operations environment. For the most part,
this follows the Unix tradition of small discrete components that
communicate in well defined ways.

This system is cross platform capable. It will run under Windows as well
as Unix like environments without a code rewrite. This allows you to
write your code once and run it wherever.

Installation of this system is fairly straight forward. You can install
it in the usual Perl fashion or there are build scripts for creating
Debian and RHEL install packages. Please see the included README for
details.

This package provides the modules and procedures to interact with a
Message Queue Server. It will retrieve messages, parse them and then
store them in an appropiate datastore. The currently defined datastores
are SQLite, Logstash and SQL Databases. The provided modules can handle 
alerts and json logging.

Extended documentation is available at: http://scm.kesteb.us/trac

