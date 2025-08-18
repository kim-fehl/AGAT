package AGAT::TestTempDir;
use strict;
use warnings;
use Exporter 'import';
use Test::TempDir::Tiny qw(tempdir);
use File::chdir;

our @EXPORT = qw(setup_tempdir);

sub setup_tempdir {
    my $dir = tempdir();
    $CWD    = $dir;
    return $dir;
}

INIT {
    setup_tempdir();
}

1;
