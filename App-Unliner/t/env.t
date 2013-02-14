use strict;

use Test::More tests => 2;

use Config;
my $perlpath = $Config{perlpath};


is(`cmdvar=outer ENVVAR="rofl copter" $perlpath -I lib bin/unliner t/programs/env.unliner --cmdvar asdf`,
   "rofl copter:asdf\n");

is(`cmdvar=outer ENVVAR="rofl copter" $perlpath -I lib bin/unliner t/programs/env.unliner`,
   "rofl copter:outer\n");
