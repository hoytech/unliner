package App::Unliner::Grammar::PostProc;

use common::sense;


sub brace_block {
  my $o = shift;
  $o =~ s/^[{]|[}]$//g;
  return $o;
}

sub arg {
  my $o = shift;
  ## FIXME: handle \ escapes properly
  $o =~ s/^'|'$//g if $o =~ /^'/;
  $o =~ s/^"|"$//g if $o =~ /^"/;
  return $o;
}

1;
