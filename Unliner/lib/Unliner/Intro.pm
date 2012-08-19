package Unliner::Intro;

1;

__END__


=encoding utf-8

=head1 Introduction to Unliner


=head1 A day in the life

... of a unix plumber.

Let's say you have a huge access log file in a typical Apache-like format like this:

    10.9.2.1 - - [10/Oct/2012:03:53:11 -0700] "GET /report.cgi HTTP/1.0" 200 724083

However, you notice that report.cgi is chewing up a lot of CPU time. Who is responsible? Let's find out the IP addresses that are hitting this URL the most so we can track them down.

The first step is to extract out just the requests for report so we'd probably do something like this:

    $ grep "GET /report.cgi" access.log

Now we'll extract the IP address:

    $ grep "GET /report.cgi" access.log | awk '{print $1}'

Next we add the standard C<sort | uniq -c | sort -rn> pipeline, along with C<head> so the results don't scroll off the screen:

    $ grep "GET /report.cgi" access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 5

And we finally get our nice report:

    3271039 10.3.0.29
       1912 10.9.2.7
       1897 10.9.2.1
        292 10.9.2.3
        101 10.9.2.4

Looks like we've found our culprit.



=head2 You want it to do what?

Usually one-liners entered in your shell are thrown away after they are used because it's so easy to re-create them as necessary. That's one reason why unix pipes are cool.

Besides, as soon as your pipelines reach the threshold of a full line or two of text, they start become very hard to read and modify (though I confess I've gotten a lot of use out of crazy long pipelines before). At this point, usually the one-liner is re-written as a "real" program.

The point of unliner is provide an intermediate stage between a one-liner and a "real" program. And you might even find that there is no need to make it a "real" program after all.

Turning your one-liner into an unliner just requires a C<def main { }> around it:

    def main {
      grep "GET /report.cgi" access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 5
    }

If you save this in the file C<log-report> now your program can be invoked with this command:

    $ unliner log-report

You could also put a L<https://en.wikipedia.org/wiki/Shebang_(Unix)|shebang line> at the top of your script, C<chmod +x> it and run it directly.



=head2 Arguments

The unliner program above is unfortunately very specific. For instance, the C<access.log> filename is hard-coded. However, the arguments to the unliner are available in the variable C<$@>, just like in regular shell:

    def main {
      grep "GET /report.cgi" $@ | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 5
    }

Now we have to pass in an C<access.log> argument (otherwise it will read input from standard input):

    $ unliner log-report access.log

We can parameterise other aspects of the unliner program too. For example, let's suppose we wanted to control the number of lines that are included in the report. To do this we add a "prototype":

    def main(head|h=i) {
      grep "GET /report.cgi" $@ | awk '{print $1}' | sort | uniq -c | sort -rn | head -n $head
    }

Now we need to add a new head argument to our invocation:

    $ unliner log-report access.log --head 5

The C<head|h=i> is a L<Getopt::Long> argument definition. It means that the official name of this argument is C<head>, that there is an alias C<h>, and that the argument is required to be an integer number. Because C<h> is an alias we could also use that as the argument:

    $ unliner log-report access.log -h 5

However, if you forget to type one of these arguments, it will error out with:

    head: : invalid number of lines

Ideally it would have a default value for C<head>. that can be accomplished by including the argument definition with the default value in parentheses, (kind of like in lisp programming):

    def main((head|h=i 5)) {
      grep "GET /report.cgi" $@ | awk '{print $1}' | sort | uniq -c | sort -rn | head -n $head
    }

Environment variables are also available so C<$HOME> and such will work.


=head2 Defs

The C<def main { }> that surrounds our program isn't special in any way except that it happens to be what is called when your program is run. You can create other defs and they can be invoked by your main def. They're kind of like subroutines which explains the name def (analogy: Python).

For example, we could move the C<awk> command into a C<ip-extractor> def, and the tallying logic into a C<tally> def:

    def main((head|h=i 5)) {
      grep "GET /report.cgi" $@ | ip-extractor | tally | head -n $head
    }

    def ip-extractor {
      awk '{print $1}'
    }

    def tally {
      sort | uniq -c | sort -rn
    }

The exact same sequences of processes will be created with this program as the previous. However, defs help you organize pipeline components better.





=head2 Def Modifiers

The contents of all the defs we've seen so far are in a custom unliner language called B<sh> which is kind of like bourne shell/bash but a little bit different (differences are explained here FIXME).

However, def modifiers can be used to change the language inside the def body. Modifiers go in between the def name/prototype and the body. One language modifier that can be used is C<perl>. It causes the def body to be interpreted as perl code. For example:

    def body-size-extractor : perl {
      ## body size is the last field in the log

      while (<STDIN>) {
        print "$1\n" if /(\d+)$/;
      }
    }

This def could also have been written in sh, but dealing with shell escapes is sometimes annoying:

    def body-size-extractor {
      perl -e 'while(<STDIN>) { ... }'
    }

Def modifiers themselves sometimes take arguments. For example, perl defs take the C<-n> switch which makes the while loop implied (just like the perl binary).

    def body-size-extractor : perl -n {
      print "$1\n" if /(\d+)$/;
    }




=head2 Templates

A useful def modifier to know is C<template>. It processes your def body with L<Template Toolkit|http://template-toolkit.org/> before it passes it on to whatever language type it is. Because the template has access to the def's arguments, this lets you conditionally include pipeline components.

Let's say we wanted to add a C<filter-localhost> switch to our log-report unliner that will exclude requests from localhost (127.0.0.1) from the tally. This can be accomplished with templates:

    def main((head|h=i 5), filter-localhost) : template {
      grep "GET /report.cgi" $@ | ip-extractor |

      [% IF filter_localhost %]  ## Note: - changes to _
        grep -v '^127\.0\.0\.1$' |
      [% END %]

      tally | head -n $head
    }

    def ip-extractor {
      awk '{print $1}'
    }
 
    def tally {
      sort | uniq -c | sort -rn
    }

After template processing the def body should be valid sh language (in this case). If the C<--filter-localhost> option isn't passed in, no grep process will ever be created.
