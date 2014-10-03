package App::Unliner::Language;

use common::sense;

use Carp;
use Digest::SHA1;
use Getopt::Long;

use App::Unliner::Util;
use App::Unliner::Grammar;
use App::Unliner::Grammar::PostProc;



our $registry = {
  sh => 'App::Unliner::Language::Shell',
  exec => 'App::Unliner::Language::Exec',
  perl => 'App::Unliner::Language::Perl',
  python => 'App::Unliner::Language::Python',
};




sub render_as_pipeline {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;

  $self->parse_args();
  $self->process_tt();
  $self->process();

  return $self->construct_pipeline();
}


sub construct_pipeline {
  my ($self) = @_;

  my $body_digest = Digest::SHA1::sha1_hex($self->{def_body});

  my $dir = App::Unliner::Util::get_temp_dir();

  my $filename = "$dir/$body_digest";
  open(my $fh, '>', $filename) || die "couldn't write temp file: $!";
  print $fh $self->{def_body};
  close($fh);

  my $command_to_run = $self->command_to_run();

  if (!ref $command_to_run) {
    $command_to_run = [ $command_to_run ];
  }

  return [{
           shell_arg => [
             @{ $command_to_run },
             $filename,
             @{ $self->{argv} },
           ],
         }];
}



sub parse_args {
  my ($self) = @_;


  $self->{context} = {};

  foreach my $prototype_elem (@{ $self->{def_prototype}->{prototype_elem} }) {
    if (exists $prototype_elem->{shell_arg}) {
      my $arg_name = $prototype_elem->{get_opt_arg};
      $arg_name = $1 if $arg_name =~ /^([\w-]+)/;

      my $default_value = App::Unliner::Grammar::PostProc::arg($prototype_elem->{shell_arg});

      $self->{context}->{$arg_name} = $default_value;
    }
  }


  if ($self->{def_modifiers}->{args}->{'pass-through'} || $self->{def_modifiers}->{args}->{pass_through}) {
    $self->getopt_config('pass_through');
  } else {
    $self->getopt_config();
  }

  my @get_opt_args;

  foreach my $prototype_elem (@{ $self->{def_prototype}->{prototype_elem} }) {
    push @get_opt_args, $prototype_elem->{get_opt_arg};
  }

  $self->getopt_from_array($self->{argv}, $self->{context}, @get_opt_args);
}


sub process_tt {
  my ($self) = @_;

  return unless $self->{def_modifiers}->{args}->{template};

  require Template;

  my $template = Template->new;

  my $context = {};

  foreach my $k (keys %{ $self->{context} }) {
    my $transformed_k = $k;
    $transformed_k =~ s/-/_/g;
    $context->{$transformed_k} = $self->{context}->{$k};
  }

  my $output;

  $template->process(\$self->{def_body}, $context, \$output)
    || die $template->error();

  $self->{def_body} = $output;
}



sub command_to_run {
  die "override me";
}

sub process {
}




## Too bad we can't use GetOpt long's OO interface because it doesn't expose getoptionsfromarray

sub getopt_config {
  my ($self, @more_config) = @_;

  ## This is unix-style setup

  Getopt::Long::Configure('default', 'bundling', 'no_ignore_case', 'no_auto_abbrev', @more_config);
}


sub getopt_from_array {
  my ($self, $argv, $context, @get_opt_args) = @_;

  Getopt::Long::GetOptionsFromArray($argv, $context, @get_opt_args)
    || croak "arg parsing failed for def " . $self->{def_name};
}


sub get_argv {
  my ($self) = @_;

  my @argv = @{ $self->{def_modifiers}->{args}->{$self->command_to_run()} };

  return \@argv;
}



1;
