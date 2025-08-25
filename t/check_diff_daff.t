use strict;
use warnings;
use Test::More;
use AGAT::TestUtilities qw(check_diff);

plan skip_all => 'daff not installed' if system('daff version > /dev/null 2>&1') != 0;

open my $got, '>', 'got.csv' or die $!;
print {$got} "a,b\n1,2\n";
close $got;

open my $expected, '>', 'expected.csv' or die $!;
print {$expected} "a,b\n1,2\n";
close $expected;

check_diff('got.csv','expected.csv','daff diff', '', 1);

done_testing;
