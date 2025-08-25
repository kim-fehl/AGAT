#!/usr/bin/perl -w

package AGAT::AGAT;

use strict;
use warnings;
use Exporter;

use Getopt::Long;
use Getopt::Long::Descriptive qw(describe_options);
use Pod::Usage;
use AGAT::AppEaser ();
use Bio::Tools::GFF;

use AGAT::OmniscientI;
use AGAT::OmniscientO;
use AGAT::OmniscientTool;
use AGAT::Config;
use AGAT::Config::Model ();
use AGAT::Levels;
use AGAT::OmniscientStat;
use AGAT::Utilities;
use AGAT::PlotR;

our $VERSION     = "v1.5.1";
our $CONFIG; # This variable will be used to store the config and will be available from everywhere.
our @ISA         = qw( Exporter );
our @EXPORT      = qw( get_agat_header print_agat_version get_agat_config handle_levels get_log_path resolve_common_options common_spec resolve_config describe_script_options );

sub import {
    AGAT::AGAT->export_to_level(1, @_); # to be able to load the EXPORT functions when direct call; (normal case)
    AGAT::OmniscientI->export_to_level(1);
    AGAT::OmniscientO->export_to_level(1);
    AGAT::OmniscientTool->export_to_level(1);
    AGAT::Config->export_to_level(1);
    AGAT::Levels->export_to_level(1);
    AGAT::OmniscientStat->export_to_level(1);
    AGAT::Utilities->export_to_level(1);
    AGAT::PlotR->export_to_level(1);
}

=head1 SYNOPSIS

  Meta package for conveniency. It allows to call all packages needed in once to deal with Omniscient data structure:
  $omniscient{'other'){'header'}[value, value]
  $omniscient->{"level1"}{$primary_tag}{$id}=$feature;
  $omniscient->{"level2"}{$primary_tag}{$parent} = [$feature,$feature];
  $omniscient->{"level3"}{$primary_tag}{$parent} = [$feature,$feature,$feature];

	It also contains function to deal with general features e.g. configuration file,
	AGAT version, AGAT header...

=head1 DESCRIPTION

    Omniscient packages are non-OO packages use to handle any kind of gtf/gff data.

=head1 AUTHOR

    Jacques Dainat - jacques.dainat@nbis.se

=cut

# ==============================================================================
#                          			=== MAIN ===

# Provide version
sub print_agat_version{
	print $VERSION."\n";
}

# Provide header
sub get_agat_header{

  my $header = qq{
 ------------------------------------------------------------------------------
|   Another GFF Analysis Toolkit (AGAT) - Version: $VERSION                      |
|   https://github.com/NBISweden/AGAT                                          |
|   National Bioinformatics Infrastructure Sweden (NBIS) - www.nbis.se         |
 ------------------------------------------------------------------------------
};

	return $header;
}

# Provide AGAT information
sub print_agat_info{
	my $header = get_agat_header();
	print <<MESSAGE
	$header 
AGAT checks, fixes, pads missing information (features/attributes) of any
kind of GTF/GFF (GXF) files and create complete, sorted and standardised 
GFF/GTF formated files. Over the years it has been enriched by many many
tools to perform just about any tasks that is possible related to GTF/GFF
format files (sanitizing, conversions, merging, modifying, filtering, FASTA
sequence extraction, adding information, etc). Comparing to other methods
AGAT is robust to even the most despicable GTF/GFF files.

By default AGAT automatically selects the appropriate parser and generates
a GFF3 output. This can be tuned via the config file.

AGAT contains 2 types of scripts: 
=================================

1) _sp_ prefix (slurp)
---------------
Data is loaded into memory via the AGAT parser that removes duplicate features, 
fixes duplicated IDs, adds missing ID and/or Parent attributes, deflates factorized 
attributes (attributes with several parents are duplicated with uniq ID), add missing 
features when possible (e.g. add exon if only CDS described, add UTR if CDS and exon 
described), fix feature locations (e.g. check exon is embedded in the parent features 
mRNA, gene), etc.
The AGAT parser defines relationship between features using 3 levels.
(e.g Level1=gene; Level2=mRNA,tRNA; Level3=exon,cds,utr)
The feature type information is stored within the 3rd column of a GXF file.
The parser needs to know to which level a feature type is part of. This information
is stored by default in a yaml file provided with the tool. We have implemented the
most common feature types met in gff/gtf files. If a feature type is not yet handle
by the parser it will throw a warning. You can easily inform the parser how
to handle it (level1, level2 or level3) by modifying the feature_levels.yaml file.

To access the AGAT feature_levels file: agat levels --expose

The  yaml file will appear in the working folder. By default, AGAT uses the
feature_levels.yaml file from the working directory when any.

AGAT parser phylosophy:
 a) Parse by Parent/child relationship
          or gene_id/transcript_id
   b) ELSE Parse by a comon tag (an attribute value shared by feature that must be grouped together.
           By default we are using locus_tag and gene_id as locus tag, but you can specify the one of your choice vi the config.
     c) ELSE Parse sequentially (features are grouped in a bucket, and the bucket change at each level2 feature met, and bucket(s) are linked to the first l1 top feature met)


2) _sq_ prefix (sequential):
---------------------
The gff file is read and processed from its top to the end line by line via the bioperl parser.
This is memory efficient, but no sanity check will be performed by the AGAT parser.

Configuration
=============

AGAT has a configuration file: agat_config.yaml

To access the AGAT config file: agat config --expose

The config yaml file will appear in the working folder. By default, AGAT 
uses the config file from the working directory when any.
The configuration can be used to change output format, to merge loci,
to activate tabix output, etc. (For _sq_ scripts only input/output format 
configuration parameters are used).
MESSAGE
}

sub get_log_path {
        my ($common, $config) = @_;
        $common ||= {};
        $config ||= {};
        return $common->{log_path} if defined $common->{log_path};
        return undef if defined $config->{log} && !$config->{log};
        return $config->{log_path} if $config->{log_path};
        my ($file) = $0 =~ /([^\\\/]+)$/;
        return $file . ".agat.log";
}

# Return shared Getopt::Long::Descriptive option descriptors
sub common_spec {
        my $schema = AGAT::Config::Model::schema();
        my @spec;
        for my $name (sort keys %$schema){
                my $cli = $schema->{$name}{cli} or next;
                push @spec, [ $cli, $schema->{$name}{description} ];
        }
        push @spec,
          [ 'config|c=s',                'Configuration file' ],
          [ 'out|o|outfile|output=s',    'Output file or folder' ],
          [ 'help|h',                    'Show this help', { shortcircuit => 1 } ],
          [
                'quiet|q',
                'Disable progress bar and verbose output',
                { implies => { debug => 0, verbose => 0, progress_bar => 0 } }
          ],
          { getopt_conf => ['pass_through'] };
        return @spec;
}

# Merge CLI values with configuration defaults and compute log path
sub resolve_config {
        my ($opt) = @_;
        my %cli = %{ $opt || {} };
        $cli{output} = delete $cli{out} if exists $cli{out};
        return resolve_common_options( \%cli );
}

# Helper to parse script-specific options together with common ones
sub describe_script_options {
        my ($header, @spec) = @_;
        my ($opt, $usage);
        eval {
                ( $opt, $usage ) = describe_options( "$header\n\n%c %o", @spec, common_spec() );
                1;
        } or do {
                ( my $err = $@ ) =~ s/\s+in call to .*//;
                $err =~ s/\s+at .*//s;
                pod2usage( { -message => $err, -exitstatus => 1, -verbose => 1 } );
        };

        pod2usage( { -verbose => 99, -exitstatus => 0, -message => "$header\n" } )
          if $opt->help;

        my $config = resolve_config($opt);
        return ( $opt, $usage, $config );
}

# Merge command-line options with configuration defaults using AppEaser,
# returning a unified hash where CLI values take precedence.
sub resolve_common_options {
        my ($cli) = @_;
        my %cli = %{ $cli || {} };

        if (!%cli) {
                my ($opt) = describe_options('%c %o', common_spec());
                %cli = %{$opt};
        }

        my $config_file = delete $cli{config};
        my $config = get_agat_config({
                config_file_in => $config_file,
                verbose        => $cli{verbose},
        });

        my $log_path = get_log_path( \%cli, $config );

        for my $k (qw(verbose log_path debug progress_bar)) {
                $config->{"//=${k}"} = delete $config->{$k} if exists $config->{$k};
        }

        my $merged = AGAT::AppEaser::hash_merge( $config, \%cli );
        $merged->{log_path} = $log_path;
        $CONFIG = $merged;
        return $merged;
}


# load configuration file from local file if any either the one shipped with AGAT
# return a hash containing the configuration.
sub get_agat_config{
        my ($args)=@_;

        my ($config_file_provided);
        if( defined($args->{config_file_in}) ) { $config_file_provided = $args->{config_file_in};}
        my $cli_verbose = $args->{verbose};

        # First retrieve the config file path without printing anything yet
        my $config_file_checked = get_config({type => "local",
                                              config_file_in => $config_file_provided,
                                              verbose => 0});
        # Load and check the configuration
        my $instance = load_config({ config_file => $config_file_checked});
        validate_config({ config => $instance });
        my $config = $instance->config_root->dump_tree(skip_auto_write => 1);

        my $verbosity = defined $cli_verbose ? $cli_verbose : $config->{verbose};
        if ($verbosity > 0){
                print AGAT::AGAT::get_agat_header();
                # Re-run get_config to display the message about which file is used
                get_config({type => "local",
                            config_file_in => $config_file_provided,
                            verbose => $verbosity});
        }
        $config->{verbose} = $verbosity;

        # Store the config in a Global variable accessible from everywhere.
        $CONFIG = $config;

        return $config;
}

# ==============================================================================
#										=== fonction for agat caller ====

# $general is a hash reference to the overall application
# $config  is a hash reference with options
# $args    is an array reference with "residual" cmd line arguments
sub handle_main {
		my ($general, $config, $args) = @_;

		my $version = $general->{configs}[-1]{version};
		my $tools = $general->{configs}[-1]{tools};
		my $help = $general->{configs}[-1]{help};
		my $info = $general->{configs}[-1]{info};
		my $h = $general->{configs}[-1]{h};

		if($version){
			print_agat_version();
		}

		if($info){
			print_agat_info();
		}

		if($tools){
			my ($package, $filename, $line) = caller;
			my $agat_bin = $ENV{'AGAT_BIN'};
			opendir my $dir, $agat_bin or die "Cannot open directory: $!";
			my @files = readdir $dir;
			closedir $dir;
			foreach my $file (sort @files){
				# only file starting by agat_
				if ( $file =~ /^agat_/){
					print $file."\n";
				}
			}
		}

		# if help was called (or not arg provided) we let AppEaser continue to print help
		my $nb_args = keys %{$general->{configs}[-1]};
		if(! $help and ! $h and $nb_args != 0){ exit 0;}
}

# Function to manipulate levels from the agat caller
sub handle_levels {
		my ($general, $config, $args) = @_;

                my $expose = $general->{configs}[-1]{expose};
                my $help = $general->{configs}[-1]{help};
                my $verbose = $general->{configs}[-1]{verbose};

		# Deal with Expose feature OPTION
                if($expose){
                        expose_levels({ verbose => $verbose });
                        print "Feature_levels YAML file copied in your working directory\n" if $verbose;
                }

		# if help was called (or not arg provided) we let AppEaser continue to print help
		my $nb_args = keys %{$general->{configs}[-1]};
		if(! $help and $nb_args != 0){ exit 0;}

}

# Function to manipulate config from the agat caller
sub handle_config {
                my ($general, $config, $args) = @_;

                my $opts   = $general->{configs}[-1];
                my $expose = $opts->{expose};
                my $help   = $opts->{help};

                if ($opts->{quiet}) {
                        $opts->{verbose}      = 0;
                        $opts->{progress_bar} = 0;
                        $opts->{debug}        = 0;
                }

                if ($expose) {
                        my $config_file = get_config({ type => "original", verbose => $opts->{verbose} });
                        my $instance    = load_config({ config_file => $config_file });
                        apply_cli($instance, $opts);
                        validate_config({ config => $instance });
                        my $conf_hash = $instance->config_root->dump_tree(skip_auto_write => 1);
                        my $config_new_name = $opts->{output};
                        if ($config_new_name) {
                                expose_config_hash({ config_in => $conf_hash, config_file_out => $config_new_name });
                        }
                        else {
                                expose_config_file({
                                        config_file_in  => $config_file,
                                        config_file_out => $config_new_name,
                                        verbose         => $opts->{verbose}
                                });
                        }
                        my $config_file_used = $config_new_name // "agat_config.yaml";
                        print "Config file written in your working directory ($config_file_used)\n" if $opts->{verbose};
                }

                my $nb_args = keys %{$opts};
                if ( !$help and $nb_args != 0 ) { exit 0; }

}

# transform 0 into false and 1 into true
sub _make_bolean{
	my ($value) = @_;

	my $result="false";
	if($value and $value ne "false"){
		$result="true";
	}
	return $result;
}

1;
