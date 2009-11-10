# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RDF-Query-Client.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('RDF::Query::Client') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sparql_ask 
	= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
	. "ASK WHERE { ?book dc:title ?title . }" ;

my $sparql_select
	= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
	. "SELECT * WHERE { ?book dc:title ?title . }" ;

my $sparql_construct
	= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
	. "CONSTRUCT { ?book <http://purl.org/dc/terms/title> ?title . }\n"
	. "WHERE { ?book dc:title ?title . }" ;
	
my $q_ask       = new RDF::Query::Client($sparql_ask);
my $q_select    = new RDF::Query::Client($sparql_select);
my $q_construct = new RDF::Query::Client($sparql_construct);

my $r_ask       = $q_ask->execute('http://sparql.org/books');
my $r_select    = $q_select->execute('http://sparql.org/books');
my $r_construct = $q_construct->execute('http://sparql.org/books');

ok($r_ask->is_boolean, "ASK results in a boolean");
ok($r_select->is_bindings, "SELECT results in bindings");
ok($r_construct->is_graph, "CONSTRUCT results in a graph");

ok($r_ask->get_boolean, "ASK results as expected");