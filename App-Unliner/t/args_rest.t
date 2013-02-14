use strict;

use Test::More tests => 2;

use Config;
my $perlpath = $Config{perlpath};

my $cmd = $perlpath . q{ -I lib bin/unliner t/programs/args_rest.unliner asdf "hello world" --split1 "blah \" 'rofl'" '$@' -z 4 };
is(`$cmd`,
   q{asdf:hello world:blah " 'rofl':$@=8} . "\n");


$cmd = $perlpath . q{ -I lib bin/unliner t/programs/args_rest.unliner asdf "hello world" --split2 "blah \" 'rofl'" '$@' -z 4 };
is(`$cmd`,
   q{asdf:hello world:blah " 'rofl':$@:-z:4} . "\n");
