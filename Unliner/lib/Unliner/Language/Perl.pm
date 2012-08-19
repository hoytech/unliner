package Unliner::Language::Perl;

use common::sense;

use base qw(Unliner::Language);


sub command_to_run { 'perl' }


sub process {
  my ($self) = @_;

  $self->getopt_config();

  my $params = {
    'n' => 0,
  };

  $self->getopt_from_array($self->get_argv, $params,
                           'e', ## Ignore: implied
                           'n',
                          );

  if ($params->{n}) {
    $self->{def_body} = <<END;
LINE:
  while (<>) {
    $self->{def_body};
  }
END
  }
}




1;
