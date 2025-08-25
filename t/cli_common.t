#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Getopt::Long::Descriptive;
use AGAT::AGAT qw(common_spec);

my @args = (
    '--config', 'foo.yaml', '--output', 'bar',
    '--log', 'baz.log', '--quiet',
    '--extra', 'val'
);
local @ARGV = @args;
my ($opt) = describe_options('test %o', common_spec());

is( $opt->{config}, 'foo.yaml', 'config path parsed' );
is( $opt->{out},    'bar',      'output path parsed' );
is( $opt->{log_path}, 'baz.log', 'log path parsed' );
is( $opt->{verbose}, 0, 'quiet forces verbose 0' );
is( $opt->{debug}, 0,   'quiet disables debug' );
is( $opt->{progress_bar}, 0, 'quiet disables progress bar' );
is( $opt->{quiet}, 1, 'quiet flag set' );
is_deeply( \@ARGV, ['--extra', 'val'], 'remaining args preserved' );

done_testing;
