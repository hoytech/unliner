package App::Unliner;

use common::sense;

our $VERSION = '0.009';

1;



=head1 NAME

App::Unliner - Untangle your unix pipeline one-liners

=head1 SYNOPSIS

B<Note>: This page is a high-level overview of unliner. For a introduction and manual, see L<App::Unliner::Intro>.

Simplest way to install unliner is with cpanminus:

    curl -sL https://raw.github.com/miyagawa/cpanminus/master/cpanm | sudo perl - App::Unliner

Here is an unliner script to display response code tallies from standard apache logs. Save it in the file C<reportgen>:

    #!/usr/bin/env unliner

    def main {
        extract-response-codes $@ | tally
    }

    def extract-response-codes : perl -n {
        ## HTTP response code is 2nd last field
        print "$1\n" if /(\d\d\d) \S+$/;
    }

    def tally {
        sort | uniq -c | sort -rn
    }

Now make C<reportgen> executable:

    $ chmod a+x reportgen

Now you can run C<reportgen> like a normal program:

    $ ./reportgen /var/www/log/access.log
      43628 200
       1911 301
        201 404
          6 500


=head1 SEE ALSO

For a more detailed description of unliner, see the introduction: L<App::Unliner::Intro>.

L<Unliner github repo|https://github.com/hoytech/unliner>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Doug Hoyte.

This module is licensed under the same terms as perl itself.
