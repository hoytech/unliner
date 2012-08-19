package Unliner::Util;

use common::sense;

use File::Temp;

my $dir;

sub get_temp_dir {
  return $dir if defined $dir;

  $dir = File::Temp->newdir();

  my $prev_sigint = $SIG{INT};

  $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = sub {
    undef $dir;
    $prev_sigint->() if defined $prev_sigint;
  };

  return $dir;
}



sub re_shell_quote {
  my $arg = shift;

  if ($arg =~ /['"\s]/) {
    $arg =~ s/'/\\'/g;
    $arg = "'$arg'";
  }

  return $arg;
}


1;
