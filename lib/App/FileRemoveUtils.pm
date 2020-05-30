package App::FileRemoveUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(delete_all_empty_files delete_all_empty_dirs);

our %SPEC;

$SPEC{delete_all_empty_files} = {
    v => 1.1,
    summary => 'Delete all empty (zero-sized) files recursively',
    args => {
    },
    features => {
        dry_run=>{default=>1},
    },
    examples => [
        {
            summary => 'Show what files will be deleted (dry-mode by default)',
            src => 'delete-all-empty-files',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Actually delete files (disable dry-run mode)',
            src => 'delete-all-empty-files --no-dry-run',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub delete_all_empty_files {
    require File::Find;
    my %args = @_;

    my @files;
    File::Find::find(
        sub {
            -l $_; # perform lstat instead of stat
            return unless -f _;
            return if -s _;
            push @files, "$File::Find::dir/$_";
        },
        '.'
    );

    for my $f (@files) {
        if ($args{-dry_run}) {
            log_info "[DRY-RUN] Deleting %s ...", $f;
        } else {
            log_info "Deleting %s ...", $f;
            unlink $f or do {
                log_error "Failed deleting %s: %s", $f, $!;
            };
        }
    }

    [200];
}

$SPEC{delete_all_empty_dirs} = {
    v => 1.1,
    summary => 'Delete all empty (zero-sized) subdirectories recursively',
    args => {
    },
    features => {
        dry_run=>{default=>1},
    },
    examples => [
        {
            summary => 'Show what directories will be deleted (dry-mode by default)',
            src => 'delete-all-empty-dirs',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Actually delete files (disable dry-run mode)',
            src => 'delete-all-empty-dirs --no-dry-run',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub delete_all_empty_dirs {
    require File::Find;
    require File::MoreUtil;
    my %args = @_;

    my %dirs; # key = path, value = {subdir => 1}
    File::Find::find(
        sub {
            return if $_ eq '.' || $_ eq '..';
            return if -l $_;
            return unless -d _;
            return if File::MoreUtil::dir_has_non_subdirs($_);
            my $path = ($File::Find::dir eq '.' ? '' : "$File::Find::dir/"). $_;
            $dirs{$path} = { map {$_=>1} File::MoreUtil::get_dir_subdirs($_) };
        },
        '.'
    );

    for my $dir (sort { length($b) <=> length($a) } keys %dirs) {
        if ($args{-dry_run}) {
            if (!(keys %{ $dirs{$dir} })) {
                log_info "[DRY-RUN] Deleting %s ...", $dir;
                $dir =~ m!(.+)/(.+)! or next;
                my ($parent, $base) = ($1, $2);
                delete $dirs{$parent}{$base};
            }
        } else {
            if (File::MoreUtil::dir_empty($dir)) {
                log_info "Deleting %s ...", $dir;
                rmdir $dir or do {
                    log_error "Failed deleting %s: %s", $dir, $!;
                };
            }
        }
    }

    [200];
}

1;
#ABSTRACT: Utilities related to removing/deleting files

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<rmhere> from L<App::rmhere>

=cut
