use strict;

use Test::More tests => 1;

use Config;
my $perlpath = $Config{perlpath};


like(`UNLINER_DEBUG=1 $perlpath -I lib bin/unliner t/programs/cat_opts.unliner 2>&1`,
   qr/CMD: wc -l$/m);
