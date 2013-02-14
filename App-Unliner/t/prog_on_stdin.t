use strict;

use Test::More tests => 2;

use Config;
my $perlpath = $Config{perlpath};


my $output = `$perlpath -I lib bin/unliner < t/programs/prog_on_stdin.unliner`;
like($output, qr/^20\n$/);

$output = `$perlpath -I lib bin/unliner - < t/programs/prog_on_stdin.unliner`;
like($output, qr/^20\n$/);
