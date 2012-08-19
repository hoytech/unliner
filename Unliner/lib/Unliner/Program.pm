package Unliner::Program;

use common::sense;

use Data::Dumper;

use Unliner::Util;
use Unliner::Grammar;
use Unliner::Program::Compiled;


sub new {
  my ($class, %args) = @_;

  my $self = {};
  bless $self, $class;

  $self->{dir} = Unliner::Util::get_temp_dir();

  if ($ENV{UNLINER_DEBUG}) {
    print STDERR "TMP: $self->{dir}\n";
  }

  my $prev_sigint = $SIG{INT};

  $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = sub {
    undef $self->{dir};
    $prev_sigint->() if defined $prev_sigint;
  };

  return $self;
}




sub compile_file {
  my ($self, $filename) = @_;


  # Load file

  open(my $fh, '<', $filename)
    || die "couldn't read unliner script '$filename': $!";

  my $file_contents = do { local $/; <$fh> };

  close($fh);


  ## Parse file

  my $parsed;

  if ($file_contents =~ $Unliner::Grammar::parsers->{file_parser}) {
    $parsed = \%/;
  } else {
    my $err = Dumper(\@!);
    die "couldn't parse unliner script '$filename': ($err)";
  }


  ## Process each directive

  my $defs;

  foreach my $directive (@{$parsed->{file}->{directive}}) {
    if ($directive->{include}) {
      #print "INCLUDING $directive->{include}->{package}\n";
      die "include not impl";
    } elsif ($directive->{def}) {
      $defs->{$directive->{def}->{name}} = $directive->{def};
    }
  }

  $self->{defs} = { %{ $self->{defs} }, %$defs };

  return $self;
}




sub run {
  my ($self, %args) = @_;

  my $def_name = $args{def_name};

  die "no such def '$def_name'"
    unless $self->{defs}->{$def_name};

  Unliner::Program::Compiled->new( program => $self,
                                   def_name => $args{def_name},
                                   argv => $args{argv},
                                 )
                            ->execute;

  return $self;

  #my $compiled_def = $self->_compile_def($args{def_name}, $args{argv});
  #$self->_interpreter($compiled_def);
}



1;
