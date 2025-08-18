package AGAT::TestTempDir;
use strict;
use warnings;
use Exporter 'import';
use Test::TempDir::Tiny qw(tempdir);
use File::chdir;

our @EXPORT = qw(setup_tempdir);
my @DIRS;    # keep temp dirs alive until program end

sub setup_tempdir {
    my $dir = tempdir();
    $CWD = $dir;
    push @DIRS, $dir;
    return $dir;
}

INIT {
    setup_tempdir();
}

1;
