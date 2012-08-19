package Unliner::Language::Shell;

use common::sense;

use Unliner::Language;
use base 'Unliner::Language';

use Data::Dumper;

use Unliner::Grammar;


sub process {
}


sub construct_pipeline {
  my ($self) = @_;

  my $def_parsed; 

  if ($self->{def_body} =~ $Unliner::Grammar::parsers->{pipeline_parser}) {
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

  $arg = Unliner::Grammar::PostProc::arg($arg);

  return @{ $self->{argv} } if ($arg eq '$@');

  return $arg;
}



1;
