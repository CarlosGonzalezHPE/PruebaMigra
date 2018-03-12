#!/usr/bin/perl -w
#-------------------------------------------------------------------------------
# DEG for Orange Spain
#
# HPE CMS Iberia, 2017-2018
#-------------------------------------------------------------------------------

use warnings;
use File::Find;
use File::Path;
use Sys::Hostname;
use Socket;

####################
# variables

use constant {
  CRITICAL => 1,
  ERROR    => 2,
  WARNING  => 3,
  INFO     => 4,
  DEBUG    => 5,
  DEBUG2   => 6,
  DEBUG3   => 7,
  DEBUG4   => 8
};

my %replaces;
my @profiles;
my @templates;
my @recursive_templates;
my @destination_directory;
my $recursive_base_directory;

my $destination="./";
my $log_level=INFO;
my $recursive=0;
my $load_env=0;
my $usage="
Usage:
  build.pl -t <template> [<template>...] [-R] -p <profile> [<profile> ...] [-d <destination>] [-l <log_level>] [-R] [-e]
  build.pl -h
";

my $current_file = "";
my $current_line = -1;

my @replaces_check_variable;
my @replaces_check_section;

my $end_on_replace_error = 1;

####################
# functions

sub print_log {
  print "$_[0]\n";
}

sub logCritial {
  if($log_level>=CRITICAL){
    print_log("CRITICAL: $_[0]");
  }
}

sub logError {
  if($log_level>=ERROR){
    print_log("ERROR: $_[0]");
  }
}

sub logWarning {
  if($log_level>=WARNING){
    print_log("WARNING: $_[0]");
  }
}

sub logInfo {
  if($log_level>=INFO){
    print_log("INFO: $_[0]");
  }
}

sub logDebug {
  if($log_level>=DEBUG){
    print_log("DEBUG: $_[0]");
  }
}

sub logDebug2 {
  if($log_level>=DEBUG2){
    print_log("DEBUG2: $_[0]");
  }
}

sub logDebug3 {
  if($log_level>=DEBUG3){
    print_log("DEBUG3: $_[0]");
  }
}

sub logDebug4 {
  if($log_level>=DEBUG4){
    print_log("DEBUG4: $_[0]");
  }
}

# recursive replace
sub replace_vars {
  $string=shift;
  $section=shift;
  logDebug2("  REPLACE => input string: '".$string."'");
  while($string =~ /<%(([\w\-]+\.)*)(@?\w+(\[\w+\])*)%>/){
    $original_variable=$1.$3;
    $selected_section=$1;
    $variable=$3;
    logDebug3("  REPLACE =>   replacing $variable ($original_variable)");
    $ok=0;
    if($selected_section eq ""){
      $selected_section=$section;
    }else{
      $_=$selected_section;
      s/\.$//;
      $selected_section=$_;
      logDebug3("  REPLACE =>   selected section: $selected_section");
    }
    while($selected_section =~ /^(.+)\.([^\.]+)$/){
      if(exists $replaces{$selected_section.".".$variable}){
        logDebug3("  REPLACE =>     $variable in $selected_section");
        $key=$selected_section.".".$variable;
        $ok=1;
        last;
      }else{
        $selected_section=$1;
      }
    }
    if(!$ok){
      if(exists $replaces{$selected_section.".".$variable}){
        logDebug3("  REPLACE =>     $variable in $selected_section");
        $key=$selected_section.".".$variable;
      }elsif(exists $replaces{"DEFAULT.".$variable}){
        logDebug3("  REPLACE =>     $variable in DEFAULT");
        $key="DEFAULT.".$variable;
      }else{
        if($end_on_replace_error){
          logError("(FILE:$current_file LINE:$current_line) Variable $variable can't be replaced (current section $section)");
          die "(FILE:$current_file LINE:$current_line) Variable $variable can't be replaced (current section $section)";
        }else{
          logWarning("(FILE:$current_file LINE:$current_line) Variable $variable can't be replaced (current section $section)");
        }
      }
    }

    logDebug3("  REPLACE =>     $variable replaced by '".$replaces{$key}."'");

    $_=$original_variable;
    s/\[/\\\[/g;
    s/\]/\\\]/g;
    $original_variable=$_;

    $_=$string;
    s/<%$original_variable%>/$replaces{$key}/g;
    $string=$_;
    logDebug3("  REPLACE =>   replace result: '".$string."'");
  }
  logDebug2("  REPLACE => final result '".$string."'");
  return $string;
}

sub recursive_template_filter {
  if(-f){
    if($File::Find::dir =~ /^$recursive_base_directory\/*(([^\/].*)?)$/){
      logDebug3("Extracted subdirectory '".$1."' of file '".$File::Find::name."' directory '".$File::Find::dir."' (current directory '".$recursive_base_directory."')");
      push(@recursive_templates,$File::Find::name);
      if($1 eq ""){
        push(@destination_directory,$destination);
      }else{
        push(@destination_directory,$destination."/".$1);
      }
    }else{
      logError("Could not extract subdirectory of file '".$File::Find::name."' directory '".$File::Find::dir."' (current directory '".$recursive_base_directory."')");
      die "Could not extract subdirectory of file '".$File::Find::name."' directory '".$File::Find::dir."' (current directory '".$recursive_base_directory."')";
    }
  }
}

####################
# Main

# reading arguments
$arg_mode=0;
while (defined ($arg = shift)){
  if($arg =~ /^-/){
    if($arg =~ /^-p|--profiles?$/){
      $arg_mode=1;
      logDebug("arg_mode = ${arg_mode}");
    }elsif($arg =~ /^-t|--templates?$/){
      $arg_mode=2;
    }elsif($arg =~ /^-h|--help$/){
      print $usage,"\n";
      exit 0;
    }elsif($arg =~ /^-l|--log_level$/){
      $arg_mode=3;
    }elsif($arg =~ /^-d|--destination$/){
      $arg_mode=4;
    }elsif($arg =~ /^-R|--recursive$/){
      $recursive=1;
    }elsif($arg =~ /^-e|--env$/){
      $load_env=1;
    }else{
      logError("Unknown option $arg");
      die "Unknown option $arg\n";
    }
  }else{
    if($arg_mode==0){
      logError("Incorrect arguments\n".$usage);
      die "Incorrect arguments\n".$usage;
    }elsif($arg_mode==1){
      push(@profiles,$arg);
    }elsif($arg_mode==2){
      push(@templates,$arg);
    }elsif($arg_mode==3){
      if($arg =~ /^[0-9]+$/){
        $log_level=$arg;
      }else{
        logError("Incorrect arguments\n".$usage);
        die "Incorrect arguments\n".$usage;
      }
      $arg_mode=0;
    }elsif($arg_mode==4){
      $destination=$arg;
      $arg_mode=0;
    }
  }
}
if($#templates<0){
  logError("Incorrect arguments\n".$usage);
  die "Incorrect arguments\n".$usage;
}

# formating destination directory
$destination =~ /^(.*[^\/])?[\/]*$/;
$destination = $1;


# loading enviroment variables
if($load_env){
  logInfo("ENV => Loading enviroment variables");
  foreach $env_var (keys %ENV) {
    logDebug("ENV => Loading enviroment variable ".$env_var."=".$ENV{$env_var});
    $replaces{'ENV.OS.'.$env_var}=$ENV{$env_var};
  }
}

# loading profiles
foreach $input_profile (@profiles) {
  logInfo("PROFILE => Loading profile $input_profile");
  open PROFILE, $input_profile or die "Could not open ".$input_profile.". ".$!;
  $current_file=$input_profile;
  $section="DEFAULT";
  $lineno = 1;
  while (defined ($input_line=<PROFILE>)) {
    $current_line=$lineno;
    chomp $input_line;
    logDebug2("PROFILE =>   input line: ".$lineno.":'".$input_line."'");
    # variable
    if($input_line =~ /^[ \t]*(@?\w+|\w+(\[\w+\])*)=(.*[^ \t]|)[ \t]*$/){ # (<VARIABLE>=VALUE or <VARIABLE>[n]=VALUE)
      $value=$3;
      if($1 eq '@ITERATION'){
        $replaces{$section.'.@ITERATION'}=1;
        if($value =~ /^(.+),(\w+)$/){
          logDebug2("PROFILE =>     iteration:".$1." variable:".$2." section:".$section);
          # checking replace
          push(@replaces_check_variable,$1);
          push(@replaces_check_section,$section);
          $replaces{$section.'.@ITERATION_COUNT'}=$1;
          $replaces{$section.'.@ITERATION_VAR'}=$2;
          $replaces{$section.'.'.$2}=1;
        }else{
          logError('(FILE:'.$current_file.' LINE:'.$current_line.') Syntax error @ITERATION');
          die '(FILE:'.$current_file.' LINE:'.$current_line.') Syntax error @ITERATION';
        }
      }else{
        logDebug2("PROFILE =>     checking replace");
        # checking replace
        push(@replaces_check_variable,$value);
        push(@replaces_check_section,$section);
        $replaces{$section.".".$1}=$value;
      }
    # section
    }elsif($input_line =~ /^[ \t]*\[([\w\.\-]+)\][ \t]*$/){
      $section=$1;
      logDebug2("PROFILE =>     section: $section");
    }elsif($input_line !~ /^ *\#/ and $input_line !~ /^[ \t]*$/){
      logError("$input_profile: Syntax error in line $lineno");
      die "(FILE:$current_file LINE:$current_line) $input_profile: Syntax error in line $lineno";
    }
    $lineno++;
  }
}

# Checking replaces after loading profiles
logInfo("PROFILE => Checking variable references");
$end_on_replace_error=0;
foreach $check_replaces_value (@replaces_check_variable) {
  $check_replaces_section = shift(@replaces_check_section);
  # checking replace without replace
  replace_vars($check_replaces_value,$check_replaces_section);
}
$end_on_replace_error=1;

# templates
if($recursive){
  foreach $x (0..@templates-1) {
    $input_template=$templates[$x];
    if(-d $input_template){
      $_=$input_template;
      s|/+|/|g;
      s|/$||;
      $recursive_base_directory=$_;
      find(\&recursive_template_filter, $recursive_base_directory);
    }else{
      push(@recursive_templates,$input_template);
      push(@destination_directory,$destination);
    }
  }
  @templates=@recursive_templates;
}

foreach $x (0..@templates-1) {
  $input_template=$templates[$x];
  if($recursive){
    $destination=$destination_directory[$x];
  }

  my $section;
  $current_file=$input_template;
  $current_line=-1;

  if($input_template =~ /^((.*\/)?)([^\/]+)$/){
    $section=$3;
  }else{
    logError("Invalid filename format $input_template");
    die "(FILE:$current_file LINE:$current_line) Invalid filename format $input_template";
  }

  logInfo("TEMPLATE => Opening template $input_template (Section $section)");

  my $iteration_count=-1;
  my $iteration_id;
  if(exists $replaces{$section.'.@ITERATION'}){
    $iteration_count=replace_vars($replaces{$section.'.@ITERATION_COUNT'},$section);
    $iteration_id=$replaces{$section.'.@ITERATION_VAR'};
    logDebug2("TEMPLATE =>   Iteration: count=".$iteration_count." var=".$iteration_id);
    if($iteration_count !~ /^[0-9]+$/){
      logError('Syntax error @ITERATION');
      die '(FILE:'.$current_file.' LINE:'.$current_line.') Syntax error @ITERATION';
    }
    if($iteration_count>0){
      logInfo("TEMPLATE =>   Destination directory '".$destination."'");
    }else{
      logInfo("TEMPLATE =>   Output disable (0 iterations)");
    }
  }else{
    logInfo("TEMPLATE =>   Destination directory '".$destination."'");
  }

  $iteration_index=1;
  while($iteration_index<=$iteration_count || ($iteration_count<0 && $iteration_index==1)){

    $output_file_enabled=1;
    if($iteration_count>0){
      logDebug2("TEMPLATE =>   ITERATION $iteration_index");
      $replaces{$section.'.'.$iteration_id}=$iteration_index;
      if((exists $replaces{$section.'.@ENABLED'} && lc(replace_vars($replaces{$section.'.@ENABLED'},$section)) eq "false") || (exists $replaces{$section.'.@ENABLED['.$iteration_index.']'} && lc(replace_vars($replaces{$section.'.@ENABLED['.$iteration_index.']'},$section)) eq "false")){
        $output_file_enabled=0;
      }
    }else{
      if(exists $replaces{$section.'.@ENABLED'} && lc(replace_vars($replaces{$section.'.@ENABLED'},$section)) eq "false"){
        $output_file_enabled=0;
      }
    }

    if(!$output_file_enabled){
      logInfo("TEMPLATE =>   Output disable");
    }else{

      my $file_out;

      if($iteration_count>0){
        if(exists $replaces{$section.'.@OUTPUT['.$iteration_index.']'}){
          $file_out=$replaces{$section.'.@OUTPUT['.$iteration_index.']'};
        }else{
          $file_out=$replaces{$section.'.@OUTPUT'};
        }
        if(!defined $file_out or $file_out eq ""){
          logError('@OUTPUT is mandatory with @ITERATION mode');
          die '(FILE:'.$current_file.' LINE:'.$current_line.') @OUTPUT is mandatory with @ITERATION mode';
        }
      }else{
        $file_out=$replaces{$section.'.@OUTPUT'};
        if(!defined $file_out or $file_out eq ""){
          $file_out=$section;
          logDebug('TEMPLATE =>   @OUTPUT is not defined. Using default file name '."'".$file_out."'");
        }
      }
      $file_out=replace_vars($file_out,$section);

      mkpath($destination);

      logInfo("TEMPLATE =>   Creating file ".$destination."/".$file_out);

      open FILE_OUT, "> ".$destination."/".$file_out or die "Could not create file ".$destination."/".$file_out.". ".$!;

      open TEMPLATE, $input_template or die "Could not open ".$input_template.". ".$!;

      $level=0;
      my %section_level;
      $section_level{0}=$section;

      my %section_iteration;
      my %section_iteration_id;
      my %section_begin;
      $section_iteration{0}=0;
      $section_begin{0}=0;

      my %section_enabled;
      $section_enabled{0}=1;

      my @INPUT = <TEMPLATE>;
      $lineno = 0;
      while (defined ($input_line=$INPUT[$lineno])) {
        $current_line=$lineno+1;
        chomp $input_line;

        logDebug2("TEMPLATE[$lineno] =>   input line: '".$input_line."'");

        if($input_line =~ /^[ \t]*\[\#(.*)\#\][ \t]*$/){ # [#<COMMAND>#]
          if($1 =~ /^SECTION_BEGIN:(\w+)$/){
            $level++;
            $section=$section.".".$1;
            $section_level{$level}=$section;

            logDebug2("TEMPLATE[$lineno] =>     Section begins. Current level $level. Current section $section");

            if(!$section_enabled{$level-1}){
              logDebug2("TEMPLATE[$lineno] =>     Section not enabled because of previous section");
              $section_enabled{$level}=0;
            }elsif(exists $replaces{$section.'.@ENABLED'}){
              logDebug2("TEMPLATE[$lineno] =>     Replacing enabler data ".$replaces{$section.'.@ENABLED'});
              $enabled=replace_vars($replaces{$section.'.@ENABLED'},$section);
              if(lc($enabled) eq "true"){
                logDebug2("TEMPLATE[$lineno] =>     Section enabled: TRUE");
                $section_enabled{$level}=1;
              }elsif(uc $enabled eq "FALSE"){
                logDebug2("TEMPLATE[$lineno] =>     Section enabled: FALSE");
                $section_enabled{$level}=0;
              }else{
                logError('TEMPLATE['.$lineno.']: Syntax error @ENABLED');
                die "(FILE:$current_file LINE:$current_line) Syntax error ".'@ENABLED';
              }
            }else{
              $section_enabled{$level}=1;
            }

            $section_iteration{$level}=1;

            if(exists $replaces{$section.'.@ITERATION'}){

              $iteration_count_2=replace_vars($replaces{$section.'.@ITERATION_COUNT'},$section);
              $iteration_id_2=$replaces{$section.'.@ITERATION_VAR'};

              logDebug2("TEMPLATE[$lineno] =>     Iteration: count=".$iteration_count_2." var=".$iteration_id_2);

              if($iteration_count_2 !~ /^[0-9]+$/){
                logError('TEMPLATE['.$lineno.']: Syntax error @ITERATION');
                die '(FILE:'.$current_file.' LINE:'.$current_line.') Syntax error @ITERATION';
              }

              logDebug2("TEMPLATE[$lineno] =>     $iteration_count_2 section iterations into variable $iteration_id_2. Section begin in $lineno");

              $section_iteration{$level}=$iteration_count_2;
              $section_iteration_id{$level}=$iteration_id_2;
              $replaces{$section.'.'.$iteration_id_2}=1;
              $section_begin{$level}=$lineno;
            }
          }elsif($1 =~ /^SECTION_END$/){

            logDebug2("TEMPLATE[$lineno] =>     Section ends");

            if($section_iteration{$level}>1){
              logDebug2("TEMPLATE[$lineno] =>     Next iteration. Go to ".$section_begin{$level});
              $section_iteration{$level}--;
              $replaces{$section.'.'.$section_iteration_id{$level}}++;
              $lineno=$section_begin{$level};
            }else{
              $level--;
              if($level<0){
                logError("TEMPLATE[$lineno]: Could not close section");
                die "(FILE:$current_file LINE:$current_line.) Could not close section";
              }
              $section=$section_level{$level};
              logDebug2("TEMPLATE[$lineno] =>     Section closed. Current level $level. Current section $section");
            }
          }else{
            logError("TEMPLATE[$lineno]: Invalid control line $input_line");
            die "(FILE:$current_file LINE:$current_line.) Invalid control line $input_line";
          }
        }else{
          if($section_enabled{$level}){
            logDebug2("TEMPLATE[$lineno] =>     Replacing line '".$input_line."'");

            $value=replace_vars($input_line,$section);

            print FILE_OUT $value."\n";
          }
        }

        $lineno++;
      }

    }

    $iteration_index++;
  }

}

exit 0;
