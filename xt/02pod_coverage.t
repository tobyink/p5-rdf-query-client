use Test::More skip_all => "There are a lot of deliberately undocumented public methods.";
use Test::Pod::Coverage;

my @modules = qw(RDF::Query::Client);
pod_coverage_ok($_, "$_ is covered")
	foreach @modules;
done_testing(scalar @modules);

