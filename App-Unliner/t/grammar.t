use strict;

use Test::More tests => 1;

use Config;
my $perlpath = $Config{perlpath};


ok(`echo | UNLINER_DEBUG=1 $perlpath -I lib bin/unliner t/programs/grammar.unliner 2>&1`
   =~ m{CMD: grep 'hello\\ world' \| .*? \| grep world \| .*? -ne 's/blah/bluh/g; print' \| head -n 1});
