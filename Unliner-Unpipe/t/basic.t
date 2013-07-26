## make ; LD_LIBRARY_PATH=blib/arch/auto/Unliner/Unpipe/ perl -I lib "-MExtUtils::Command::MM" t/basic.t

use strict;

use Unliner::Unpipe;

use Test::More tests => 4;
use POSIX;


sub run_test {
  my ($lines_to_print, $head_cutoff) = @_;

  my ($out_r, $out_w);
  pipe $out_r, $out_w;

  my $upipe = Unliner::Unpipe->new;
  my $upipe2 = Unliner::Unpipe->new;

  if (!fork) {
    $upipe->install_after_exec(1, 'w');
    exec('perl', '-e', q{
      $|=1;

      for $z (1 .. $ARGV[0]) {
        print "hello world $z\n";
        #print STDERR "hello world $z\n";
      }
    }, $lines_to_print);
  }

  if (!fork) {
    $upipe->install_after_exec(0, 'r');
    $upipe2->install_after_exec(1, 'w');
    exec('perl', '-ne', q{
      print uc($_);
    });
  }

  if (!fork) {
    $upipe2->install_after_exec(0, 'r');
    POSIX::dup2(fileno($out_w), 1);
    exec('head', '-n', $head_cutoff);
  }

  undef $out_w;

  my $output;

  {
    local $/; $output = <$out_r>;
  }

  wait for (1..3);

  return $output;
}



{
  my $val = run_test(100000, 1000000);
  my @vs = split /\n/, $val;
  ok(@vs == 100000);
  my $i = 1;
  foreach my $v (@vs) {
    die "Wrong! ($v)" unless $v =~ /^HELLO WORLD $i$/;
    $i++;
  }
  ok(1);
}

{
  my $val = run_test(1000000, 100000);
  my @vs = split /\n/, $val;
  ok(@vs == 100000);
  my $i = 1;
  foreach my $v (@vs) {
    die "Wrong! ($v)" unless $v =~ /^HELLO WORLD $i$/;
    $i++;
  }
  ok(1);
}
