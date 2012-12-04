package App::Unliner::Grammar;

use common::sense;

use Regexp::Grammars;


our $parsers = {};



qr{
  <grammar: App::Unliner::Grammar::ShellArg>

  <token: shell_arg>
    (?: \\ . | [^'"\s|#] )+ |
    ' [^']* ' |
    " (?: \\ . | [^"] )* "
}xs;



qr{
  <grammar: App::Unliner::Grammar::File>

  <extends: App::Unliner::Grammar::ShellArg>

  <token: ws>
    (?: \s++ | [#][^\n]*\n | [/][*] .*? [*][/] )*

  <rule: file>
    ^ <[directive]>* $

  <rule: directive>
    <def> | <include>

  <rule: def>
    def <name> <prototype>? <[def_modifier]>* <brace_block> ;?

  <rule: include>
    include <package> ;?

  <rule: brace_block>
    <matchline>
    [{]
      (?:
        [^{}]* |
        <.brace_block> |
        <fatal: (?{"Unterminated block starting on line $MATCH{matchline}"})>
      )*
    [}]

  <rule: name>
    [-_\w]+

  <rule: package>
    [\w]+ (?: [:][:] [\w]+ )*

  <rule: prototype>
    <matchline>
    [(]
      (?:
        <[prototype_elem]>*? % , |
        <fatal: (?{"Unterminated prototype starting on line $MATCH{matchline}"})>
      )
    [)]

  <rule: prototype_elem>
    <matchline>
    (?:
      <get_opt_arg> |
      (?:
        [(]
          <get_opt_arg>
          (?: <shell_arg> )?
        [)]
      ) |
      <fatal: (?{{
                   msg => "Bad GetOpt::Long prototype element on line $MATCH{matchline}",
                   ctx => "$CONTEXT",
                }})>
    )

  <token: get_opt_arg>
    [^\s,()]+


  <rule: def_modifier>
    : <[shell_arg]>+? % \s
}xs;



qr{
  <grammar: App::Unliner::Grammar::Pipeline>

  <extends: App::Unliner::Grammar::ShellArg>

  <token: ws>
    (?: \s++ | [#][^\n]*\n )*

  <rule: pipeline>
    ^ <[command]>+ % [|] $

  <rule: command>
    <[shell_arg]>+ % \s
}xs;



$parsers->{file_parser} = qr{
  <extends: App::Unliner::Grammar::File>
  <file>
}xs;

$parsers->{pipeline_parser} = qr{
  <extends: App::Unliner::Grammar::Pipeline>
  <pipeline>
}xs;





1;
