package App::Unliner::Intro;

1;

__END__



=encoding utf-8

=head1 Introduction to Unliner


=head2 A day in the life

... of a unix plumber.

Let's say you have a huge access log file in a typical Apache-like format like this:

    10.9.2.1 - - [10/Oct/2012:03:53:11 -0700] "GET /report.cgi HTTP/1.0" 200 724083

However, you notice that report.cgi is chewing up lots of system resources. Who is responsible? Let's find out the IP addresses that are hitting this URL the most so we can track them down.

The first step is to extract out the requests for report.cgi so we'd probably do something like this:

    $ grep "GET /report.cgi" access.log

Now we'll extract the IP address:

    $ grep "GET /report.cgi" access.log | awk '{print $1}'

Next we add the standard C<sort | uniq -c | sort -rn> tallying pipeline:

    $ grep "GET /report.cgi" access.log | awk '{print $1}' | sort | uniq -c | sort -rn

Oops, the important bit scrolled off the screen. Let's add a C<head> process to limit the output:

    $ grep "GET /report.cgi" access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 5

And we finally get our nice report:

    3271039 10.3.0.29
        912 10.9.2.7
        897 10.9.2.1
        292 10.9.2.3
        101 10.9.2.4

Looks like we've found our culprit.



=head2 Installing unliner

If you want to follow along with this tutorial, or start coding right away, the easiest way to install unliner is with cpanminus:

    curl -sL https://raw.github.com/miyagawa/cpanminus/master/cpanm | sudo perl - App::Unliner



=head2 You want it to do I<what>?

Usually one-liners entered in your shell are thrown away after they are used because it's so easy to re-create them as necessary. That's one reason why unix pipes are so cool.

Besides, as soon as your pipelines reach a full line or two of text they start to become very hard to work with (though I confess I've gotten a lot of use out of crazy long pipelines before). At this point, usually the one-liner is re-written as a "real" program.

The point of unliner is to provide an intermediate stage between a one-liner and a real program. And you might even find that there is no need to make it a real program after all.

To turn your one-liner into an unliner just wrap a C<def main { }> around it like this:

    def main {
      grep "GET /report.cgi" access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 5
    }

If you save this in the file C<log-report> then your unliner program can be invoked with this command:

    $ unliner log-report

You could also put a L<shebang line|https://en.wikipedia.org/wiki/Shebang_(Unix)> at the top of your script:

    #!/usr/bin/env unliner

Now if you C<chmod +x log-report> you can run it directly.



=head2 Defs

The C<def main { }> isn't a special type of def except that it happens to be what is called when your program is invoked (precedent: C). You can create other defs and they can be invoked by your main def and other defs, kind of like subroutines (name precedent for def: lisp, Python).

For example, we could move the C<awk> command into a C<ip-extractor> def, and the tallying logic into a C<tally> def:

    def main {
      grep "GET /report.cgi" access.log | ip-extractor | tally | head -n 5
    }

    def ip-extractor {
      awk '{print $1}'
    }

    def tally {
      sort | uniq -c | sort -rn
    }

The same sequences of processes will be created with this program as with the previous. However, defs let you organize and re-use pipeline components better.





=head2 Arguments

The unliner program shown so far is not very flexible. For instance, the C<access.log> filename is hard-coded.

To fix this the arguments passed in to our log-report program are available in the variable C<$@>, just like in a shell script:

    def main {
      grep "GET /report.cgi" $@ | ip-extractor | tally | head -n 5
    }

Now we can pass in a log file argument to our program (otherwise it will read input from standard input):

    $ unliner log-report access.log

Note that $@ escapes whitespace like bourne shell's C<"$@">. Actually it just passes the argument array untouched through to the process (grep in this case) so the arguments can contain any characters. The bourne equivalent of unquoted C<$@> and C<$*> are not supported because they cause way too many bugs (use templates below if you need to do this).

We can parameterise other aspects of the unliner program too. For example, let's suppose we wanted to control the number of lines that are included in the report. To do this we add a "prototype":

    def main(head|h=i) {
      grep "GET /report.cgi" $@ | ip-extractor | tally | head -n $head
    }

The prototype indicates that the main def requires arguments. Since the main def is the entry-point, these arguments must come from the command line:

    $ unliner log-report access.log --head 5

C<head|h=i> is a L<Getopt::Long> argument definition. It means that the official name of this argument is C<head>, that there is a single-dash alias C<h>, and that the argument is required to be an integer number. Because C<h> is an alias we could also use that as the argument:

    $ unliner log-report access.log -h 5

However, if you forget to add one of these arguments, the head process will die with an error like C<head: : invalid number of lines>.

In order to have a default value for a paramater, you put parentheses around the argument definition followed by the default value (precedent: lisp):

    def main((head|h=i 5)) {
      grep "GET /report.cgi" $@ | ip-extractor | tally | head -n $head
    }

Environment variables are also available so C<$HOME> and such will work.

None of these variables need to be quoted. They are always passed verbatim to the underlying command.

Defs internal to your program accept arguments in exactly the same way:

    def main {
      grep "GET /report.cgi" $@ | ip-extractor | tally | my-head -n 5
    }

    def my-head((n=i 10)) {
      head -n $n
    }






=head2 Def Modifiers

The contents of all the defs we've seen so far are in a custom unliner language called B<Shell>. C<: sh> is redundant because Shell is the default language.

Shell is mostly like bourne shell/bash but a little bit different. The differences are described in the distribution's TODO file. Some differences are deliberate and some are just features that haven't been implemented yet. One difference is that unliner uses perl-style backslashed single quotes in single quoted string literals, not bourne shell-style (if you don't know what the bourne shell-style is, consider yourself lucky).

Def modifiers can be used to change how the def body is interpreted by changing the language to something other than Shell. Modifiers go in between the def name/prototype and the body. One language modifier that can be used is C<perl>. It causes the def body to be interpreted as perl code. For example:

    def body-size-extractor : perl {
      while (<STDIN>) {
        ## body size is the last field in the log
        print "$1\n" if /(\d+)$/;
      }
    }

This def could also have been written in sh, but dealing with shell escapes is sometimes annoying:

    def body-size-extractor {
      perl -e 'while(<STDIN>) { ... }'
    }

Def modifiers themselves sometimes take arguments. For example, perl defs can take the C<-n> switch which implicitly adds a loop (just like the perl binary):

    def body-size-extractor : perl -n {
      print "$1\n" if /(\d+)$/;
    }

Another supported language is python:

    def wrap-in-square-brackets : python {
      import sys

      for line in sys.stdin:
        line = line[:-1] # chop newline
        print "[" + line + "]"
    }

Note that python is very noisy when it receives a SIGPIPE so polite pipeline components should manually catch it and then exit silently.

A general-purpose "language" is exec. It is useful for pipeline components using programs that there are no custom languages for. For instance, the following defs are equivalent:

    def second-column {
      awk -F, '{ print $2 }'
    }

    def second-column : exec awk -F, -f {
      { print $2 }
    }

Note that the C<-f> is required because awk doesn't follow the common scripting language convention where a program path is the first argument.

Github pull requests for new languages appreciated.




=head2 Templates

Another def modifier is C<template>. This modifier processes your def body with L<Template Toolkit|http://template-toolkit.org/> before it passes it on to whatever language type is specified. Because the template has access to the def's arguments, this lets you conditionally include pipeline components.

Let's say we wanted to add a C<filter-localhost> switch to our log-report unliner that will exclude requests from localhost (127.0.0.1) from the tally. This can be accomplished with templates:

    def main((head|h=i 5), filter-localhost) : template {
      grep "GET /report.cgi" $@ |
      ip-extractor |

      [% IF filter_localhost %]  ## Note: - changes to _
        grep -v '^127\.0\.0\.1$' |
      [% END %]

      tally |
      head -n $head
    }

    def ip-extractor {
      awk '{print $1}'
    }
 
    def tally {
      sort | uniq -c | sort -rn
    }

We can now enable this option from the command line:

    $ unliner log-report access.log --filter-localhost

A grep process wil only be created if the C<--filter-localhost> option is passed in.

Remember that templates are processed as strings before the language even sees them. For example, here is how you could take advantage of the head "negative number" trick:

    def my-head((n=i 5)) : template {
      head -[% n %]
    }

Above is OK because C<n> is guaranteed to be an integer, but when using templates always be careful about escaping or sanitising values.




=head2 Debugging

In order to see the actual pipeline being run, you can set the environment variable C<UNLINER_DEBUG> and it will print some information to standard error:

    $ UNLINER_DEBUG=2 unliner log-report access.log --filter-localhost
    unliner: TMP: /tmp/GPtXapOfib
    unliner: TMP: Not cleaning up temp directory because UNLINER_DEBUG >= 2
    unliner: CMD: grep 'GET /report.cgi' access.log | perl /tmp/GPtXapOfib/56ba8ad7a6431cbe6b64835c97e248d27a4234a0 | sort | uniq -c | sort -rn | head -n 5

Note that when you write defs in languages like perl and python, scripts will be created in a temporary directory and executed from there.



=head2 Optimisation

Unliner does pipeline optimisation by default. Currently only spurious cat processes are optimised away.

=over

=item * Leading cats

If a pipeline begins with a cat of no arguments, that cat is removed and no cat process is created. If a pipeline begins with a cat of exactly one argument, then that file is opened and dup2()ed to STDIN.

=item * Trailing cats

If a pipeline ends with a trailing cat, that cat is removed unless STDOUT is a terminal. Trailing cats are useful to prevent a program from doing special terminal formatting things like adding ANSI colours.

=item * Internal cats

All internal cats with no arguments are removed. Such cats aren't as silly as they sound. Sometimes pipeline components have leading or trailing cats for some reason. When these components are used in pipelines, internal cats result. This optimisation will stop any unnecessary cat processes from being created.

=back

Consider the following unliner script:

    def main {
      cat $@ | cat | cat | cat | wc -l | cat | cat
    }

Because of the spurious cat optimisations, running it like so won't start a single cat process:

    unliner lots-of-cats.unliner file.txt > output.txt

It is optimised to the following equivalent:

    wc -l < file.txt > output.txt
