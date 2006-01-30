use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Writer::Simple',
    AUTHOR              => 'Alberto Simoes <ambs@cpan.org>',
    VERSION_FROM        => 'lib/XML/Writer/Simple.pm',
    ABSTRACT_FROM       => 'lib/XML/Writer/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'XML::DT' => 0.42,
                  'Test::More' => 0,
                  'XML::DTDParser' => 2.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Writer-Simple-*' },
);
