use strict;

use Test::More tests => 4;

use Config;
my $perlpath = $Config{perlpath};


## EOF at front

my $output = `$perlpath -e 'print "rofl\nblah\n" for (1..7267)' | $perlpath -I lib bin/unliner t/programs/basic.unliner`;

like($output, qr/^(?:\d+: WERD: \d+: \d+: ROFL\n){7267}$/);
$output =~ /^(\d+): WERD: (\d+): (\d+): ROFL\n/;
ok($1 != $2 && $2 != $3);



## EOF at end:

$output = `$perlpath -e 'print "rofl\nblah\n" while 1' | $perlpath -I lib bin/unliner t/programs/basic.unliner |head -n 9831`;

like($output, qr/^(?:\d+: WERD: \d+: \d+: ROFL\n){9831}$/);
$output =~ /^(\d+): WERD: (\d+): (\d+): ROFL\n/;
ok($1 != $2 && $2 != $3);
