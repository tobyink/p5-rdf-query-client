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

requires            'Carp'               => 0;
recommends          'DBD::SQLite'        => 0;
recommends          'HTTP::LRDD'         => '0.101';
requires            'RDF::Trine'         => '0.133';
test_requires       'LWP::Simple'        => 0;
requires            'LWP::UserAgent'     => 0;
requires            'namespace::clean'   => 0;
requires            'Scalar::Util'       => 0;
test_requires       'Test::More'         => '0.61';
requires            'URI::Escape'        => 0;

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
