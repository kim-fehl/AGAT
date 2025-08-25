#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use AGAT::Config qw(load_config apply_cli validate_config);

my $root = "$Bin/..";
my $cfg = load_config({ config_file => "$root/share/agat_config.yaml" });

apply_cli($cfg, { verbose => 3, progress_bar => 0 });
validate_config({ config => $cfg });
is( $cfg->config_root->fetch_element('verbose')->fetch, 3, 'verbose overridden' );
is( $cfg->config_root->fetch_element('progress_bar')->fetch, 0, 'progress_bar overridden' );

eval { apply_cli($cfg, { bogus => 1 }); };
like( $@, qr/Unknown option/, 'unknown flag rejected' );

done_testing;
