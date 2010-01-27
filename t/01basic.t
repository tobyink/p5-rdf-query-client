use Test::More tests => 5;
BEGIN { use_ok('RDF::Query::Client') };

diag("The following tests will FAIL if you don't have network access.\n");
diag("But you can safely ignore warnings from DBD about tables being locked.\n");

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
