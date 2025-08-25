#!/usr/bin/perl -w

package AGAT::Config::Model;

use strict;
use warnings;
use Config::Model;
use Exporter 'import';

our @EXPORT_OK = qw(build_model schema);

my $schema = {
    verbose => {
        type        => 'leaf',
        value_type  => 'integer',
        default     => 1,
        min         => 0,
        max         => 4,
        description => 'Verbosity level (0-4)',
        annotation  => { cli => 'verbose|v=i' },
    },
    progress_bar => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Show progress bar',
        annotation  => { cli => 'progress_bar|progressbar!' },
    },
    log => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Write log file',
    },
    log_path => {
        type        => 'leaf',
        value_type  => 'uniline',
        default     => '',
        description => 'Log file path',
        annotation  => { cli => 'log_path|log=s' },
    },
    debug => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 0,
        description => 'Enable debug output',
        annotation  => { cli => 'debug!' },
    },
    tabix => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 0,
        description => 'Enable tabix output',
        annotation  => { cli => 'tabix!' },
    },
    merge_loci => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 0,
        description => 'Merge overlapping loci',
        annotation  => { cli => 'merge_loci!' },
    },
    throw_fasta => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 0,
        description => 'Remove embedded FASTA',
        annotation  => { cli => 'throw_fasta!' },
    },
    force_gff_input_version => {
        type        => 'leaf',
        value_type  => 'enum',
        choice      => [qw/0 1 2 2.5 3/],
        default     => '0',
        description => 'Force GFF input version',
        annotation  => { cli => 'force_gff_input_version=i' },
    },
    output_format => {
        type        => 'leaf',
        value_type  => 'enum',
        choice      => [qw/GFF GTF/],
        default     => 'GFF',
        description => 'Output format',
        annotation  => { cli => 'output_format=s' },
    },
    gff_output_version => {
        type        => 'leaf',
        value_type  => 'enum',
        choice      => [qw/1 2 2.5 3/],
        default     => '3',
        description => 'GFF output version',
        annotation  => { cli => 'gff_output_version=i' },
    },
    gtf_output_version => {
        type        => 'leaf',
        value_type  => 'enum',
        choice      => [qw/1 2 2.1 2.2 2.5 3 relax/],
        default     => 'relax',
        description => 'GTF output version',
        annotation  => { cli => 'gtf_output_version=s' },
    },
    deflate_attribute => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 0,
        description => 'Deflate multi-value attributes',
        annotation  => { cli => 'deflate_attribute!' },
    },
    create_l3_for_l2_orphan => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Create exon for orphan level2 features',
        annotation  => { cli => 'create_l3_for_l2_orphan!' },
    },
    locus_tag => {
        type        => 'list',
        cargo       => { type => 'leaf', value_type => 'uniline' },
        default_list=> ['locus_tag','gene_id'],
        description => 'Fallback attributes to determine locus',
        annotation  => { cli => 'locus_tag=s@' },
    },
    prefix_new_id => {
        type        => 'leaf',
        value_type  => 'uniline',
        default     => 'agat',
        description => 'Prefix for newly created IDs',
        annotation  => { cli => 'prefix_new_id=s' },
    },
    clean_attributes_from_template => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 0,
        description => 'Clean attributes when cloning features',
        annotation  => { cli => 'clean_attributes_from_template!' },
    },
    check_sequential => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check feature order',
        annotation  => { cli => 'check_sequential!' },
    },
    check_l2_linked_to_l3 => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check level2 linked to level3',
        annotation  => { cli => 'check_l2_linked_to_l3!' },
    },
    check_l1_linked_to_l2 => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check level1 linked to level2',
        annotation  => { cli => 'check_l1_linked_to_l2!' },
    },
    remove_orphan_l1 => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Remove orphan level1 features',
        annotation  => { cli => 'remove_orphan_l1!' },
    },
    check_all_level3_locations => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check all level3 locations',
        annotation  => { cli => 'check_all_level3_locations!' },
    },
    check_cds => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check CDS features',
        annotation  => { cli => 'check_cds!' },
    },
    check_exons => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check exon features',
        annotation  => { cli => 'check_exons!' },
    },
    check_utrs => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Create UTRs if missing',
        annotation  => { cli => 'check_utrs!' },
    },
    check_all_level2_locations => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check all level2 locations',
        annotation  => { cli => 'check_all_level2_locations!' },
    },
    check_all_level1_locations => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Check all level1 locations',
        annotation  => { cli => 'check_all_level1_locations!' },
    },
    check_identical_isoforms => {
        type        => 'leaf',
        value_type  => 'boolean',
        default     => 1,
        description => 'Remove identical isoforms',
        annotation  => { cli => 'check_identical_isoforms!' },
    },
};

sub build_model {
    my $model = Config::Model->new();
    my @elements;
    while (my ($name,$spec) = each %$schema){
        my %spec = %$spec;
        push @elements, $name => \%spec;
    }
    $model->create_config_class( name => 'AGAT', element => \@elements );
    return $model;
}

sub schema { return $schema }

1;

__END__

=head1 NAME

AGAT::Config::Model - configuration schema for AGAT

=head1 DESCRIPTION

This module defines the configuration schema for AGAT using L<Config::Model>.
Each option is described in C<\%schema> with its type, default value, allowed
choices and documentation.  The schema also stores the corresponding command
line flag in C<annotation->{cli}> so that option handling and CLI parsing stay
in sync.  Contributors can extend the configuration by editing this file and
adding new entries to C<\%schema>.

=cut

