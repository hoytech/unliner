package App::Unliner::Language::Shell;

use common::sense;

use App::Unliner::Language;
use base 'App::Unliner::Language';

use Data::Dumper;

use App::Unliner::Grammar;


sub process {
}


sub construct_pipeline {
  my ($self) = @_;

  my $def_parsed; 

  my $def_body = $self->{def_body};
  $def_body =~ s/^\s*[|]//;
  $def_body =~ s/[|]\s*$//;

  if ($def_body =~ $App::Unliner::Grammar::parsers->{pipeline_parser}) {
    $def_parsed = \%/;
  } else {
    my $err = Dumper(\@!);
    die "couldn't parse $self->{def_name}: ($err)";
  }

  my $output = $def_parsed->{pipeline}->{command};

  foreach my $pipeline_component (@$output) {
    $pipeline_component->{shell_arg} = [ map { $self->process_arg($_) } @{$pipeline_component->{shell_arg}} ];
  }

  return $output;
}


sub process_arg {
  my ($self, $arg) = @_;

  unless ($arg =~ /^'/) {
    $arg =~ s{ \$
               (?: (\w+) |
                   \{
                     (.*?)
                   \}
               )
             }{
               $self->{context}->{$2 || $1} // $ENV{$2 || $1}
             }egx;
  }

  $arg = App::Unliner::Grammar::PostProc::arg($arg);

  return @{ $self->{argv} } if ($arg eq '$@');

  return $arg;
}



1;
