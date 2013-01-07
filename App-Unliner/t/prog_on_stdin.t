use strict;

use Test::More tests => 2;


my $output = `$^X -I lib bin/unliner < t/programs/prog_on_stdin.unliner`;
ok($output =~ /^20\n$/);

$output = `$^X -I lib bin/unliner - < t/programs/prog_on_stdin.unliner`;
ok($output =~ /^20\n$/);
