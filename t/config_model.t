#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use YAML qw(LoadFile DumpFile);

use AGAT::Config qw(load_config validate_config);

my $root = catfile($Bin, '..');
my $default_cfg = catfile($root, 'share', 'agat_config.yaml');

# success loading
my $inst = load_config({ config_file => $default_cfg });
validate_config({ config => $inst });
is( $inst->config_root->fetch_element('verbose')->fetch, 1, 'default verbose loaded' );

my $tmpdir = tempdir(CLEANUP => 1);
my $tmpfile = catfile($tmpdir, 'cfg.yaml');

# missing key
my $data = LoadFile($default_cfg); delete $data->{verbose}; DumpFile($tmpfile,$data);
eval { load_config({ config_file => $tmpfile }); };
like($@, qr/verbose/, 'missing key triggers error');

# wrong type
$data = LoadFile($default_cfg); $data->{verbose} = 'loud'; DumpFile($tmpfile,$data);
eval { load_config({ config_file => $tmpfile }); };
like($@, qr/verbose/, 'wrong type triggers error');

# out of range value
$data = LoadFile($default_cfg); $data->{gff_output_version} = 5; DumpFile($tmpfile,$data);
eval { load_config({ config_file => $tmpfile }); };
like($@, qr/gff_output_version/, 'out of range triggers error');

done_testing;
