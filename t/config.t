#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use Cwd qw(abs_path);

=head1 DESCRIPTION

Test to verify other type of check. e.g. configuation call.

=cut

# Check if has to be run in Devel::Cover or not
my $script_prefix="";
if (exists $ENV{'HARNESS_PERL_SWITCHES'} ) {
  if ($ENV{'HARNESS_PERL_SWITCHES'} =~ m/Devel::Cover/) {
    $script_prefix="perl -MDevel::Cover ";
  }
}

# script to call to check the parser
my $script = "";
my $root = abs_path(catdir($Bin, '..'));
my $output_folder = catdir($Bin, 'config', 'out');
my $config = 'agat_config.yaml';

# remove config in local folder if exists

# ---- test gzip file and contain fasta ----
$script = $script_prefix . catfile($root, 'bin', 'agat');
my $correct_output = "$output_folder/$config";

system("$script config -e \\
								--no-log \\
								--no-create_l3_for_l2_orphan  \\
								--throw_fasta  \\
								--no-tabix  \\
								--output_format GTF  \\
								--gff_output_version 2  \\
								--gtf_output_version 2  \\
								--debug  \\
								--deflate_attribute  \\
								--no-check_all_level1_locations  \\
								--no-check_identical_isoforms  \\
								--no-check_utrs  \\
								--no-check_sequential  \\
								--no-check_all_level3_locations  \\
								--no-remove_orphan_l1  \\
								--no-check_cds  \\
								--no-check_l1_linked_to_l2  \\
								--verbose 3  \\
								--no-check_l2_linked_to_l3  \\
								--force_gff_input_version 3  \\
								--no-check_all_level2_locations  \\
								--locus_tag test1,test2 \\
								--no-progress_bar  \\
								--no-check_exons  \\
								--merge_loci \\
								--prefix_new_id nbisTEST \\
								--clean_attributes_from_template  ");

#run test
ok( system("diff $config $correct_output") == 0, "modif config check");
# remove file created for the test

# ----- Test Rename config file ----

my $new_config_name = "agat_config_renamed.yml";
system("$script config -e --output $new_config_name --locus_tag Name");

#run test 
ok( system("if [ -e $new_config_name ];then exit 0;fi") == 0, "rename agat config file check");

# ----- Test use a renamed config file ----

system(catfile($root, 'bin', 'agat_convert_sp_gxf2gxf.pl') .
       " --gff " . catfile($Bin, 'gff_syntax', 'in', '28_test.gff') .
       " -c $new_config_name -o tmp.gff  2>&1 1>/dev/null");
#run test 
ok( system("diff tmp.gff " . catfile($Bin, 'gff_syntax', 'out', '28_correct_output.gff')) == 0, "Use custom agat config file check");

# remove file created for the test
