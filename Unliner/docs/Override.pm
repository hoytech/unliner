package Override;

use common::sense;

use base qw<Tie::Handle>;
use Symbol qw<geniosym>;


sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub DESTROY { 
  print "DESTROY\n";
}

sub CLOSE {
  print "CLOSE\n";
}

my ($r, $w);
pipe $r, $w;
tie *$r, 'Override';

close $r;
undef $r;


1;
