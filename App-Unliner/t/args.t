use strict;

use Test::More tests => 4;


is(`printf "aa\nbb\ncc\n" | perl -I lib bin/unliner t/programs/args.unliner -n 2`,
   "aa\nbb\n");

is(`printf "aa\nbb\ncc\n" | perl -I lib bin/unliner t/programs/args.unliner --lines 2 -u`,
   "AA\nBB\n");

is(`printf "aa\nbb\ncc\n" | perl -I lib bin/unliner t/programs/args.unliner -un 2 -p bb`,
   "AA\nCC\n");

is(`perl -I lib bin/unliner t/programs/args.unliner -n 2 --junk "not default"`,
   "not default\n");
