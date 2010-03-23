use strict;
use warnings;

use inc::Module::Install;

my $dist = 'RDF-Query-Client';
my $fn   = "lib/$dist.pm"; $fn =~ s#-#/#g;

name                $dist;
perl_version_from   $fn;
version_from        $fn;
abstract_from       $fn;
readme_from         $fn;
author              'Toby Inkster <tobyink@cpan.org>';
license             'perl';

test_requires       'Test::More'     => '0.61';
test_requires       'LWP::Simple'    => 0;

requires            'Carp'           => 0;
requires            'RDF::Trine'     => 0.111;
requires            'LWP::UserAgent' => 0;
requires            'URI::Escape'    => 0;

recommends          'DBD::SQLite'    => 0;

resources(
	'homepage'   => "http://search.cpan.org/dist/$dist/",
	'repository' => "http://goddamn.co.uk/viewvc/perlmods/$dist/",
	'bugtracker' => "http://rt.cpan.org/Dist/Display.html?Queue=$dist",
	);
	
write_doap_changes;
write_doap_changes_xml;

include 'Test::Signature';
auto_install;
WriteAll(
	'meta' => 1,
	'sign' => 1,
	);
