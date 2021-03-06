use strict;

use ExtUtils::MakeMaker;

if ($^O eq "MSWin32") {
    die "test hang on Windows\nOS unsupported\n";
}

my %args = (
    NAME              => 'App::Unliner',
    VERSION_FROM      => 'lib/App/Unliner.pm',
    EXE_FILES         => [ 'bin/unliner', ],
    PREREQ_PM         => {
                           'common::sense' => 0,
                           'Regexp::Grammars' => 0,
                           'Getopt::Long' => 0,
                           'Digest::SHA1' => 0,
                           'Template' => 0,
                           'Pod::Perldoc' => 0,
                         },
    LIBS              => [],
    DEFINE            => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text lib/App/Unliner/Intro.pm > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/unliner.git',
            bugtracker => 'https://github.com/hoytech/unliner/issues',
        },
    };
}

WriteMakefile(%args);
