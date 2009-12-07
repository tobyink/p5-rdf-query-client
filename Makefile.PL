use strict;
use warnings;

use inc::Module::Install;

license             'perl';

name                'RDF-Query-Client';
author              'Toby Inkster <tobyink@cpan.org>';
perl_version_from   'lib/RDF/Query/Client.pm';
version_from        'lib/RDF/Query/Client.pm';
abstract_from       'lib/RDF/Query/Client.pm';

test_requires       'Test::More' => '0.61';

requires            'RDF::Trine'     => 0.111;
requires            'LWP::UserAgent' => 0;
requires            'URI::Escape'    => 0;

auto_install;

sign;

WriteAll;

use Pod::Text;
my $parser = Pod::Text->new (sentence => 0, width => 78);
$parser->parse_from_file('lib/RDF/Query/Client.pm', 'README');
