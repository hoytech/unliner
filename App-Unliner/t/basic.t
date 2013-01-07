use strict;

use Test::More tests => 4;


## EOF at front

my $output = `$^X -e 'print "rofl\nblah\n" for (1..7267)' | $^X -I lib bin/unliner t/programs/basic.unliner`;

ok($output =~ /^(?:\d+: WERD: \d+: \d+: ROFL\n){7267}$/);
$output =~ /^(\d+): WERD: (\d+): (\d+): ROFL\n/;
ok($1 != $2 && $2 != $3);



## EOF at end:

$output = `$^X -e 'print "rofl\nblah\n" while 1' | $^X -I lib bin/unliner t/programs/basic.unliner |head -n 9831`;

ok($output =~ /^(?:\d+: WERD: \d+: \d+: ROFL\n){9831}$/);
$output =~ /^(\d+): WERD: (\d+): (\d+): ROFL\n/;
ok($1 != $2 && $2 != $3);
