use strict;

use Test::More;

if (-x '/bin/sh') {
  plan tests => 1;
} else {
  plan skip_all => '/bin/sh not available';
  exit;
}

ok(`$^X -I lib bin/unliner t/programs/exec.unliner "some arg"`
   =~ m{^Hello from /\S+ some arg \d+$});
