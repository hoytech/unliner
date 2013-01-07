use strict;

use Test::More tests => 1;

ok(`$^X -I lib bin/unliner t/programs/exec.unliner "some arg"`
   =~ m{^Hello from /\S+ some arg \d+$});
