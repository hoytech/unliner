use strict;

use ExtUtils::MakeMaker;

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod;' .
    'pod2text README.pod | tee $(DISTVNAME)/README > README';

WriteMakefile(
    NAME              => 'Unliner::Unpipe',
    VERSION_FROM      => 'lib/Unliner/Unpipe.pm',
    PREREQ_PM         => {
                           'File::ShareDir' => 0,
                         },
    LIBS              => ['-ldl', '-lpthread'],
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => 'Unpipe.o allocator.o',
    dist => {
      PREOP => $preop,
    },
);


sub MY::linkext {
  <<'END'

linkext :: $(LINKTYPE) build_preloader
	$(NOECHO) $(NOOP)

build_preloader:
	$(CC) $(CCCDLFLAGS) $(LDDLFLAGS) allocator.c io.c preloader.c -o blib/arch/auto/Unliner/Unpipe/unliner_preloader.so $(LDLOADLIBS)

END
}
