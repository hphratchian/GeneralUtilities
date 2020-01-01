#!/usr/bin/perl
#
# POD block.  To view these comments in a formatted fashion, use perldoc or
# any of the other POD utilities to form man-style pages.
#

=head1 NAME

savefile - This script is used to save a copy of a file using a numerical
file name ending.

=head1 SYNOPSIS
This command takes a single file name as input and copies it to a new file
with a
numerical ending. The script looks for existing related files and copies the
current file to one with the numerical ending incremented by 1.

There are two additional optional arguments. The first optional argument
(second overall) is the number of numerical digits to be used. The script
pads the numerical endings with zeros. By defult, a three digit numerical
ending is used.

The second optional argument (third overall) is a debug print flag. By
default, this flag is set to zero.

=head1 USAGE

Here are some example uses of log2out...

1. To save the file a.log use the command:
      savefile a.log
   If the no saved files exist, this will copy a.log to a.log000. If files
   a.log000, a.log001, and a.log002 exist, this will copy a.log to
   a.log003.

=head1 AUTHOR

=over 2

=item Hrant P. Hratchian

=item Department of Chemistry & Chemical Biology

=item Center for Chemical Computation and Theory (ccCAT)

=item University of California, Merced

=item hhratchian@ucmerced.edu

=back

=cut

#
#
#   Get command line arguments, chomp the filename, and set defaults for
#   option(s).
#
    $filename = @ARGV[0];
    $number_of_digits = @ARGV[1];
    $print_level = @ARGV[2];
    chomp($filename);
    if(!$number_of_digits){$number_of_digits = 3};
    if(!$print_level){$print_level = 0};
    print "number_of_digits: $number_of_digits\n";
    if($print_level >= 1){print "Saving file <$filename>.\n"};
    @saved_files = glob "$filename*";
    if($print_level >= 1){print "Result of glob...\n\t<@saved_files>\n"};
    foreach $temp (@saved_files){
      chomp($temp);
      if($temp =~ /^$filename(\d+)$/){
        $used_saved_numbers[$1] = 1;
      }
    }
    $next_saved_number = sprintf "%0${number_of_digits}d", scalar @used_saved_numbers;
    $new_saved_filename = "$filename"."$next_saved_number";
    print "New saved filename: <$new_saved_filename>\n";
    `cp $filename $new_saved_filename`;

#    foreach $temp (@numbers){
#      print "$temp\n";
#      printf "%05d\n", $temp
#    }


#    if(!@log_files){@log_files=glob"*.log"};
#    print "Here are the log files:\n";
#    foreach(@log_files){
#      chomp;
#      $out_file = $_;
#      $out_file =~ s/\.log/\.out/;
#      print "Moving $_ to $out_file.\n";
#      `mv $_ $out_file`;
#    }
