#!/usr/bin/perl -w

package AGAT::Config;

use strict;
use warnings;
use YAML qw(DumpFile LoadFile);
use File::Copy;
use File::ShareDir ':ALL';
use AGAT::Utilities;
use Cwd qw(cwd);
use Exporter;
use Config::Model;
use AGAT::Config::Model qw(build_model schema);


our @ISA = qw(Exporter);
our @EXPORT = qw( load_config expose_config_file validate_config get_config expose_config_hash apply_cli );

=head1 SYNOPSIS

This is the code to handle AGAT's config file. Accessing file is slow, the
values from the yaml files will be stored within OMNISCIENT when accessed the
first time.

=head1 DESCRIPTION

 This lib contains functions to parse YAML config files and store the values within
 OMNISCIENT and functions to assess the values.

=head1 AUTHOR

  Jacques Dainat - jacques.dainat@nbis.se

=cut

#	-----------------------------------CONSTANT-----------------------------------

# This is the default one, but can be changed by the user
my $config_file= ("agat_config.yaml");

#	------------------------------------GENERAL------------------------------------	 


# @Purpose: Load yaml file, check all is set, shift false to 0, return the config
# @input: 4 =>	verbose, config_file (path), log, debug
# @output: 1 => hash
# @Remark: none
sub load_config{
        my ($args) = @_;

        my $path = $args->{config_file} or do { warn "No config file provided!"; exit };

        my $model = build_model();
        my $instance = $model->instance( root_class_name => 'AGAT' );
        my $root = $instance->config_root;

        if (-e $path){
                my $data = LoadFile($path);
                eval { $root->load_data($data); 1 } or die "Invalid configuration file $path: $@";
        }

        validate_config({ config => $instance });
        return $instance;
}

# @Purpose: Select which config file to use (local or original shiped with AGAT)
# If type=original we only take the original config
# If type=local we try first to take the local one. If none we take the original one.
sub get_config{
	my ($args) = @_;

	# -------------- INPUT --------------
	# -- Declare all variables and fill them --
        my ( $verbose, $log, $debug, $type, $config_file_in ) ;
        if( ! defined($args->{verbose}) ) {
                if( defined $AGAT::AGAT::CONFIG->{verbose} ) {
                        $verbose = $AGAT::AGAT::CONFIG->{verbose};
                } else {
                        $verbose = 1;
                }
        } else{ $verbose = $args->{verbose}; }
	if( ! defined($args->{log}) ) { $log = undef;} else{ $log = $args->{log}; }
	if( ! defined($args->{debug}) ) { $debug = undef;} else{ $debug = $args->{debug}; }
	if( ! defined($args->{type}) ) { $type = "local";} else{ $type = $args->{type};}
	if( !$type eq "local" and !$type eq "original" ){
		warn "type must be local or original. $type unknown!";exit;
	}
	if( ! defined($args->{config_file_in}) ) { $config_file_in = undef;} else{ $config_file_in = $args->{config_file_in}; }
	
	my $path=undef;

	# original approach trying to get the local and/or original config file
	if (! $config_file_in){
		#set run directory
		my $run_dir = cwd;

		# get local config if any
		if ($type eq "local") {
			$path = $run_dir."/".$config_file;
			if (-e $path){
				dual_print($log, "=> Using $config_file config file found in your working directory.\n", $verbose );
			} else {
				$path = undef;
			}
		}
		#otherwise use the standard location ones
		if (! $path) { 
			$path = dist_file('AGAT', $config_file);
			dual_print($log, "=> Using standard $path config file\n", $verbose );
		}
	}
	# Config file provided we must load this one !
	else{
		if (-e $config_file_in){
			$path = $config_file_in;
			dual_print($log, "=> Using provided config file $path.\n", $verbose );
		} else{
			warn "=> Config file $config_file_in does not exist! Please check the path!"; exit;
		}
	}
	return $path;
}

sub expose_config_hash{
	my ($args)=@_;

	my ($config_in, $config_file_out);
	if( ! defined($args->{config_in}) ) { $config_in = undef;} else{ $config_in = $args->{config_in};}
	if( ! defined($args->{config_file_out}) ) { $config_file_out = $config_file;} else{ $config_file_out = $args->{config_file_out};}

	DumpFile($config_file_out, $config_in);
}

# @Purpose: Write the config hash in a yaml file in the current directory 
sub expose_config_file{
        my ($args)=@_;

        my ($path_in, $config_file_out, $verbose);
        if( ! defined($args->{config_file_in}) ) { $path_in = undef;} else{ $path_in = $args->{config_file_in};}
        if( ! defined($args->{config_file_out}) ) { $config_file_out = $config_file;} else{ $config_file_out = $args->{config_file_out};}
        if( ! defined($args->{verbose}) ) { $verbose = 1;} else{ $verbose = $args->{verbose};}

        #set run directory
        if(! $path_in){
                $path_in = dist_file('AGAT', $config_file);
                dual_print(undef, "Path where $config_file is standing according to dist_file: $path_in\n", $verbose);
        }
        # copy the file locally
        my $run_dir = cwd;
        copy($path_in, $run_dir."/".$config_file_out) or die print "Copy failed: $!";
}

# @Purpose: Check config value to be sure everything is set as expected
sub validate_config{
        my ($args) = @_;
        my $cfg = $args->{config};
        my $instance;

        if (ref $cfg && $cfg->isa('Config::Model::Instance')){
                $instance = $cfg;
        } else {
                my $model = build_model();
                $instance = $model->instance( root_class_name => 'AGAT' );
                $instance->config_root->load_data($cfg);
        }

        eval { $instance->config_root->validate; 1 } or die "Configuration validation failed: $@";
        return $instance;
}

sub apply_cli{
        my ($instance, $cli) = @_;
        my $root   = $instance->config_root;
        my $schema = AGAT::Config::Model::schema();
        my %remaining = %{$cli || {}};

        for my $elt_name ($root->get_element_names){
                my $spec = $schema->{$elt_name}{cli} or next;
                my ($key) = split /[|=]/, $spec;
                next unless exists $cli->{$key};
                my $elt = $root->fetch_element($elt_name);
                my $val = $cli->{$key};
                if ($elt->get_type eq 'list'){
                        $val = ref $val eq 'ARRAY' ? $val : [ split /,/, $val ];
                }
                $elt->store($val);
                delete $remaining{$key};
        }

        for my $k (keys %remaining){
                next if $k =~ /^(config|out|outfile|output|help|expose|quiet)$/;
                die "Unknown option: $k";
        }

        return $instance;
}

1;
