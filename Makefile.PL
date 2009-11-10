use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RDF::Query::Client',
    VERSION_FROM      => 'lib/RDF/Query/Client.pm', # finds $VERSION
    PREREQ_PM         => {
	'RDF::Trine'     => '0.111',
	'URI::Escape'    => '3',
	'LWP::UserAgent' => '5',
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RDF/Query/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Inkster <mail@tobyinkster.co.uk>') : ()),
);
