use strict;

use ExtUtils::MakeMaker;

my $preop =
    'perldoc -uT lib/Unliner/Intro.pm | tee $(DISTVNAME)/README.pod > README.pod;' .
    'pod2text ../README.pod | tee $(DISTVNAME)/README > README';

WriteMakefile(
    NAME              => 'Unliner',
    VERSION_FROM      => 'lib/Unliner.pm',
    EXE_FILES         => [ 'bin/unliner', ],
    PREREQ_PM         => {
                           'common::sense' => 0,
                           'Regexp::Grammars' => 0,
                           'Getopt::Long' => 0,
                           'Digest::SHA1' => 0,
                         },
    LIBS              => [],
    DEFINE            => '',
    dist => {
      PREOP => $preop,
    },
);
