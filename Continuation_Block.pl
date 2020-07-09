#!/usr/bin/perl
#
#   This script is used to properly block a set of continuation lines in
#   FORTRAN 77 programs.  The input is given through <STDIN> and the final
#   formatted block is send to <STDOUT>.  In this way, this script is ideal
#   for execution from within a VIM buffer with, for instance, the code of
#   interest highlighted in Visual Mode.
#
#   Initial Completion Date:       2/22/2006
#   Most Recent Modification Date: 7/2/2007
#                                  Hrant P. Hratchian,
#                                  Dept. of Chemistry, Indiana University
#                                  hhratchi@indiana.edu
#
#
#   ----------------------------------------------------------------------
#   To-Do List (Known Break-Downs):
#   ----------------------------------------------------------------------
#   1. Modify script to properly block around line numbers.
#   2. Modify script to properly break lines around single-quoted strings,
#      i.e., Call SubA('This is an example').
#   3. Test to-do items #1 and #2 on lines like...
#
#      if(IPath.eq.1 .and. IStep.eq.2) Call GauErr('Unrecoverable SCF failure')
#
#      and...
#
# 1090 Format(' SCF convergence failure!  Path Direction Number',I6,
#    $  ' Point Number',I6)
#
#   ----------------------------------------------------------------------


##########################################################################
#                                                                        #
#                               MAIN CODE                                #
#                                                                        #
##########################################################################

#
#   Begin by loading the input continuation block into $cont_block_in.
#
    while (<STDIN>){
      $cont_block_in .= $_;
    }
#
#   Determine if $cont_block_in already contains continuation lines or if
#   $cont_block_in is a single line that may need to be broken into
#   separate lines with continuation characters.
#
#   The result of these tests is to set the flag $in_flag.  The possible
#   values for $in_flag and what they indicate are:
#         $in_flag = 0  ...  $cont_block_in is a single line that is under
#                            72 columns long and does not require any
#                            editing at all.
#         $in_flag = 1  ...  $cont_block_in is a single long line that
#                            needs to be broken into a proper continuation
#                            block.
#         $in_flag = 2  ...  $cont_block_in is already formatted in a
#                            continuation block form and needs to be
#                            re-blocked.
#
    chomp($cont_block_in);
    $length_cont_block_in = length($cont_block_in);
    if($cont_block_in =~ /\s{5}\$/){
      $in_flag = 2;
    }else{
      if($length_cont_block_in > 72){
        $in_flag = 1;
      }else{
        $in_flag = 0;
      }
    }
#
#   Using $in_flag to direct us, do the necessary editing.  Note, that at
#   the end of this block the newline character is appended to
#   $cont_block_out.
#
    if($in_flag == 0){
      $cont_block_out = $cont_block_in;
    }elsif($in_flag == 1){
      $cont_block_out = &replace_space_in_single_quotes_sub(0,$cont_block_in);
      $temp = &cut_condensed_cont_block_F77_sub($cont_block_out);
      $cont_block_out = $temp;
      $temp = &last_line_length_sub($cont_block_out);
      until($temp < 73){
        $temp = &cut_condensed_cont_block_F77_sub($cont_block_out);
        $cont_block_out = $temp;
        $temp = &last_line_length_sub($cont_block_out);
      }
    }elsif($in_flag == 2){
      $condensed_block = &condense_cont_block_F77_sub($cont_block_in);
      $cont_block_out = &replace_space_in_single_quotes_sub(0,$condensed_block);
      $temp = &last_line_length_sub($cont_block_out);
      until($temp < 73){
        $temp = &cut_condensed_cont_block_F77_sub($cont_block_out);
        $cont_block_out = $temp;
        $temp = &last_line_length_sub($cont_block_out);
      }
    }else{
      die "in_flag value of $in_flag INVALID!";
    }
    $cont_block_out .= "\n";
#
#   Make sure that back-ticks added for spaces inside of single quotes are
#   removed and put back to spaces.
    $cont_block_out = &replace_space_in_single_quotes_sub(1,$cont_block_out);
#
#   Print out the final result, which is given by $cont_block_out.
#
    print "$cont_block_out";


##########################################################################
#                                                                        #
#                              SUBROUTINES                               #
#                                                                        #
##########################################################################

    sub last_line_length_sub{
#
#     This routine takes a string scalar that may have newline characters
#     in it and returns the length of the last line.
#
      use strict;
      my($line) = @_;
      my($last_line_length);
      chomp($line);
      if($line =~ /^[\d\D]*\n(.*)$/){$line = $1};
      $last_line_length = length($line);
      return $last_line_length;
    }
      

    sub condense_cont_block_F77_sub{
#
#     This routine is used to condense an F77 continuation block.  The
#     input is a continuation block, including newline characters.  The
#     output is a single line of code with all of the continuation
#     characters ($) and newline characters removed.  Note that the
#     indenting of the top of the block is maintained.  Also note that NO
#     newline character is put at the end of the line.
#
#     As a bit of a hack, we replace all spaces inside of single quotes by
#     back-tick.  This way, when the text is broken-up we don't break at
#     positions within quotes.  Note that after building the block we will
#     need to put those spaces back.
#
#     In order to avoid other problems down the road, we also remove any
#     spaces that exist on either side of a comma.  Note that this is NOT
#     required by the FORTRAN standard, but rather is necessary for the
#     remainder of this script to work without choking.
#
      use strict;
      my($block_out) = @_;
      $block_out =~ s/\$//g;
      $block_out =~ s/\s*\n\s*//g;
      $block_out =~ s/ , /,/g;
      $block_out =~ s/ ,/,/g;
      $block_out =~ s/, /,/g;
      return $block_out;
    }


    sub replace_space_in_single_quotes_sub{
#
#     This routine is used to replace all spaces within single quotes by
#     back-ticks, or to put the back-ticks back to spaces.  Two arguments
#     need to be passed.  The first argument is 0 or 1 and the second
#     argument is the text being considered.  If the first argument is 0,
#     then spaces within single quotes are turned into back-ticks.  If the
#     first argument is 1, then back-ticks within single quotes are turned
#     into spaces.
#
      use strict;
      my($flag,$text_in);
      my($text_out);
#
#     Load the dummy variables.
#
      ($flag,$text_in) = @_;
#
#     Check to see if there are any single quotes in $text_in.  If not,
#     just return.
#
      if(!($text_in =~ /\'/)){return $text_in}
#
#     If $flag = 0, look for space between single-quotes and change then to
#     `.  Note that in this case we need to make sure that there are no new
#     line meta-characters in $text_in.
#
      if($flag == 0){
        if($text_in =~ /\n/){
          die "\nreplace_space_in_single_quotes_sub: No newline characters allowed!\n\n";
        }
        $text_out = $text_in;
        while($text_out =~ /\'.* .*\'/){
          $text_out =~ s/(\'.*) (.*\')/$1\`$2/;
        }
      }elsif($flag == 1){
        $text_out = $text_in;
        while($text_out =~ /\'.*\`.*\'/){
          $text_out =~ s/(\'.*)\`(.*\')/$1 $2/;
        }
      }else{
        die "\nreplace_space_in_single_quotes_sub: Invalid flag!\n\n";
      }
#
      return $text_out;
    }


    sub cut_condensed_cont_block_F77_sub{
#
#     This routine is used to do one step in the re-blocking of an F77
#     continuation block that is condensed, i.e. in a format matching the
#     output of the Routine condense_cont_block_F77_sub.  Basically, this
#     routine looks at the input variable, which should be a scalar string,
#     to find the last line (in other words the part of the string
#     following the last newline character) and it cuts it so that this
#     line does not extend beyond column 72.  The remaining part of the
#     string is appended as a new line at the end of the string.  The front
#     part of this appended new line is blocked according to the previous
#     line.  To fully re-block a condensed F77 line, one should call this
#     routine and then check to see if the last line of the string extends
#     beyond column 72.  If it does, then this routine should be called
#     again, and so on.
#
#     NOTE: Lines are cut at "(", ",", or white space.
#
      use strict;
      my($line_out) = @_;
      my($front,$init_last_line,$new_last_line,$remainder,$spaces_after_cont);
      my($temp1);
#
#     Some variable definitions:
#       $line_out -  This is the line returned by this routine.  It is
#                    initialized to the value of the line sent here.
#       $front    -  This is the part of $line_out before the last line,
#                    which will be cut in this routine.
#       $init_last_line - This is the last line of the line initially sent
#                    to this routine.
#       $new_last_line - This is the properly blocked version of
#                    $init_last_line.
#       $remainder - This is the part of $init_last_line that remains after
#                    forming $new_last_line.  The front of $remainder is
#                    properly blocked and then appended to $line_out as the
#                    new last line.
#
#       $spaces_after_cont - This is the number of spaces that need to be
#                    added to properly block $remainder.
#
#
#     Start out by parsing $front and $init_last_line.  Some care is taken
#     to check if the input line has been cut at all yet.  If not,
#     $init_last_line is the same as the input line and $front is left
#     undefined.  The way we know if this is the first time into this
#     routine is that the code has not yet been blocked as a continuation
#     block.  In other words, there shouldn't be any new-line characters
#     followed by white-space and a dollar sign ($).  In the other entries
#     to this routine, we'll see the new-line, white-space, "$" ordering
#     and break the input string so that we have a "new" last line to work
#     on.
#
      chomp($line_out);
      if($line_out =~ /^(.*\n)(\s*\$\s*[a-zA-Z0-9\+\-\,\=\(\)\.\*\/:]*)$/s){
        $front = $1;
        $init_last_line = $2;
      }else{
        $init_last_line = $line_out;
      }
#
#     Form $new_last_line from $init_last_line and then load $remainder.
#
#     Step 1: Just cut the initial last line after column 72.
      if($init_last_line =~ /^([\d\D]{72})(.*)$/){
        $new_last_line = $1;
        $remainder = $2;
      }else{
        die "\n\nLogic Error 1 in cut_condensed_cont_block_F77_sub!\n\n
          init_last_line =\n$init_last_line\n\n"
      }
#
#     Step 2: Make sure that the inital last line now ends at a reasonable
#     place, i.e. after a full variable name, etc.
      if($new_last_line =~ /^(.*[ ,])([^ ^,]*)$/){
        $new_last_line = $1;
        $remainder = $2.$remainder;
        if($new_last_line =~ /(.*[\,\(])([a-zA-Z0-9]+\([a-zA-Z0-9\+\-\,\*\=]+\,\'\`)\s*$/){
          die "\n\nIn Confusing IF block!\n\n";
          $new_last_line = $1;
          $remainder .= $2;
        }
      }else{
        die "\n\nLogic Error 2 in cut_condensed_cont_block_F77_sub!\n\n
          new_last_line =\n$new_last_line\n\n"
      }
#
#     Step 3: Make sure that we haven't cut the line in the middle of an
#     array argument.
      while($remainder =~ /^[^(]*\)\S+.*$/){
        if($new_last_line =~ /^(.*\,)([^,^(^)]+\([^(^)]+)$/){
          $new_last_line = $1;
          $remainder = $2.$remainder;
        }else{
          die "\n\nLogic Error 3 in cut_condensed_cont_block_F77_sub!\n\n";
        }
      }
#
#     Step 4: Add spaces to the front of $remainder so that the code ends
#     up properly blocked.
      if($new_last_line =~ /^([\s\d\$]*)[\.a-zA-Z\d\+\-]/){
        $temp1 = $1;
        if($temp1 =~ /\$/){
          $spaces_after_cont = length($temp1)-6;
        }else{
          $spaces_after_cont= length($temp1)-6+2;
        }
      }else{
        die "\n\nLogic Error 4 in cut_condensed_cont_block_F77_sub!\n\n
          new_last_line =\n$new_last_line\n\n"
      }
      $remainder =~ s/^\s//;
      $remainder = "     \$" . (" " x $spaces_after_cont) . $remainder;
#
#     Finalize the return value.
#
      chomp($new_last_line);
      chomp($remainder);
      if(defined($front)){
        chomp($front);
        $line_out = "$front" . "\n" . "$new_last_line" . "\n";
      }else{
        $line_out = "$new_last_line" . "\n";
      }
      $line_out = "$line_out" . "$remainder";
      return $line_out;
    }
