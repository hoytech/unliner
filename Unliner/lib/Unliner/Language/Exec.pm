package Unliner::Language::Exec;

use common::sense;

use base qw(Unliner::Language);


sub command_to_run {
  my ($self) = @_;

  return $self->{def_modifiers}->{args}->{exec}->[0];
}


1;
