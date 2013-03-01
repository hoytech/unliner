package App::Unliner::Util;

use common::sense;

use File::Temp;


require Exporter;
use base 'Exporter';
our @EXPORT = qw(debug_log);



sub debug_log {
  my $msg = shift;

  if ($ENV{UNLINER_DEBUG}) {
    print STDERR "unliner: $msg\n";
  }
}



my $dir;

sub get_temp_dir {
  return $dir if defined $dir;

  $dir = File::Temp->newdir( CLEANUP => ($ENV{UNLINER_DEBUG} < 2), );

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
