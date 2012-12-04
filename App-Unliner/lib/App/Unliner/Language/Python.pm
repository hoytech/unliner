package App::Unliner::Language::Python;

use common::sense;

use base qw(App::Unliner::Language);


sub command_to_run { 'python' }


sub process {
  my $self = shift;

  if ($self->{def_body} =~ m/^([ \t\r]*)\S/m) {
    my $spaces = $1;
    $self->{def_body} =~ s/^$spaces//mg;
  }

}


1;
