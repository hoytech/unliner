package Unliner::Unpipe;

use strict;

use File::ShareDir;

our $VERSION = '0.1';

require XSLoader;
XSLoader::load('Unliner::Unpipe', $VERSION);


sub new {
  my ($class, %args) = @_;

  my $self = {};
  bless $self, $class;

  $self->{shared_object} = $self->_find_shared_object();

  $self->{id} = unpipe_create_xs(16);
  die "Unable to create shared memory segment ($!)" if !defined $self->{id};

  return $self;
}

sub DESTROY {
  my ($self) = @_;

  unpipe_destroy_xs($self->{id});
}

sub install_now {
  my ($self, $fd, $mode) = @_;

  die "FIXME: impl"; ## requires the .so to be preloaded already
}

sub install_after_exec {
  my ($self, $fd, $mode) = @_;

  die "first arg should be a file descriptor" unless defined $fd && $fd =~ /^\d+$/;
  die "mode should be 'r' or 'w'" unless defined $mode && ($mode eq 'r' || $mode eq 'w');

  if (!defined $ENV{LD_PRELOAD}) {
    $ENV{LD_PRELOAD} = $self->{shared_object};
  } elsif ($ENV{LD_PRELOAD} =~ /unpipe/i) {
    ## already installed, do nothing
  } else {
    $ENV{LD_PRELOAD} = "$self->{shared_object} $ENV{LD_PRELOAD}";
  }

  my $fd_packed = "$fd$mode=$self->{id}";

  if (!defined $ENV{UNPIPE_FDS}) {
    $ENV{UNPIPE_FDS} = $fd_packed;
  } else {
    $ENV{UNPIPE_FDS} .= ",$fd_packed";
  }
}

sub _find_shared_object {
  my ($self) = @_;

  my $output;

  my $share_dir = eval { File::ShareDir::dist_dir("Unliner-Unpipe") };
  if (defined $share_dir) {
    $output = $share_dir . "/Unpipe.so";
    return $output if -e $output;
  };

  $output = './blib/arch/auto/Unliner/Unpipe/unliner_preloader.so';
  return $output if -e $output;

  die "Unable to locate Unpipe.so";
}

1;
