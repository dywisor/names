#!/usr/bin/env perl

package NamesMain;

use strict;
use warnings;
use feature qw( say );
use 5.10.0;

use Getopt::Long qw(:config posix_default bundling no_ignore_case );
use File::Basename;

our $VERSION = 0.1;
our $NAME    = q{names};
our $DESC    = q{make a name for yourself};

# array of all known commands
#  Note that you need to provide the corresponding action code in main()
my $COMMANDS = [
    {
        short               => 'A',
        name                => 'add',
        desc                => 'add names',
        need_dict           => 1,
        need_pool           => 0,
        default_posarg_mode => 'F'
    },

    {
        short               => 'B',
        name                => 'ban',
        desc                => 'ban names',
        need_dict           => 1,
        need_pool           => 0,
        default_posarg_mode => 'N'
    },

    {
        short               => 'D',
        name                => 'drop',
        desc                => 'delete names',
        need_dict           => 1,
        need_pool           => 0,
        default_posarg_mode => 'F'
    },

    {
        short               => 'P',
        name                => 'print-db',
        desc                => 'print names',
        need_dict           => 1,
        need_pool           => 0,
        num_posargs         => 0
    },

    {
        short               => 'f',
        name                => 'free',
        desc                => 'remove unused names',
        need_dict           => 0,
        need_pool           => 1,
        num_posargs         => 0
    },

    {
        short               => 'g',
        name                => 'get',
        desc                => 'acquire a new random name',
        need_dict           => 1,
        need_pool           => 1,
        force_posarg_mode   => 'uint',
        num_posargs         => 1,
    },

    {
        short               => 'o',
        name                => 'orphaned',
        desc                => 'print orphaned names (present in pool but not dict)',
        need_dict           => 1,
        need_pool           => 1,
        num_posargs         => 0
    },

    {
        short               => 'p',
        name                => 'print',
        desc                => 'print acquired names',
        need_dict           => 0,
        need_pool           => 1,
        num_posargs         => 0
    },

    {
        short               => 'r',
        name                => 'release',
        desc                => 'mark names as unused',
        need_dict           => 0,
        need_pool           => 1,
        default_posarg_mode => 'N'
    },

    {
        short               => 't',
        name                => 'take',
        desc                => 'register names as acquired',
        need_dict           => 1,
        need_pool           => 1,
        default_posarg_mode => 'N'
    },

    {
        short               => 'u',
        name                => 'unused',
        desc                => 'print unused names',
        need_dict           => 0,
        need_pool           => 1,
        num_posargs         => 0,
    },

    {
        short               => 'w',
        name                => 'wipe',
        desc                => 'remove names so that they may be reacquired',
        need_dict           => 0,
        need_pool           => 1,
        default_posarg_mode => 'N'
    },

    {
        short               => 'x',
        name                => 'import',
        desc                => 'register a name as acquired if new, add to dict if new',
        desc_long           => [
            'for names matching stem/suffix,',
            'add only new stems to dict',
        ],
        group               => 'cross',
        need_dict           => 1,
        need_pool           => 1,
        default_posarg_mode => 'N'
    },
];

# compute command table / help
my $COMMAND_TABLE = {};

my $COMMAND_HELP = {
    dict  => [],
    pool  => [],
    cross => []
};

foreach my $cmd (@$COMMANDS) {
    my $name;
    my $posarg_mode;

    my $help_msg_args;
    my $help_msg;
    my $help_key;

    $name = $cmd->{name};

    foreach my $key ($cmd->{short}, $cmd->{name}) {
        die unless $key;
        die "redef of command ${key}\n" if exists $COMMAND_TABLE->{$key};
        $COMMAND_TABLE->{$key} = $cmd;
    }
    # $key contains long name now

    if ( not defined $cmd->{num_posargs} ) {
        $help_msg_args = ' ...';
    } elsif ( $cmd->{num_posargs} == 0 ) {
        $help_msg_args = '';
    } elsif ( $cmd->{num_posargs} == 1 ) {
        $help_msg_args = ' <ARG>';
    } else {
        $help_msg_args = sprintf ' <ARG>{%d}', $cmd->{num_posargs};
    }

    $help_msg = sprintf
        "  %s, %-21s %s",
        $cmd->{short},
        ($cmd->{name} . $help_msg_args),
        $cmd->{desc}
    ;

    if ( exists $cmd->{force_posarg_mode} ) {
        $posarg_mode = $cmd->{force_posarg_mode};
    } else {
        $posarg_mode = $cmd->{default_posarg_mode}; # could be undef
    }

    if ( $posarg_mode ) {
        $help_msg .= sprintf ' (%s)', $posarg_mode;
    }

    if ( ( defined $cmd->{desc_long} ) && ( scalar @{ $cmd->{desc_long} } ) ) {
        $help_msg .= "\n";
        # indent by hanging indent + 2
        $help_msg .= (join "\n", map { sprintf '%30s %s', '', $_ } @{ $cmd->{desc_long} });
    }

    $help_key = $cmd->{group};
    if ( not defined $help_key ) {
        if ( $cmd->{need_pool} ) {
            $help_key = 'pool';
        } elsif ( $cmd->{need_dict} ) {
            $help_key = 'dict';
        }
    }

    if ( $help_key && exists $COMMAND_HELP->{$help_key} ) {
        push @{ $COMMAND_HELP->{$help_key} }, $help_msg;
    } else {
        $help_key ||= '<undef>';
        die "command ${name}: invalid help group: ${help_key}\n";
    }
}

my $COMMAND_HELP_DICT  = join "\n", @{ $COMMAND_HELP->{dict} };
my $COMMAND_HELP_POOL  = join "\n", @{ $COMMAND_HELP->{pool} };
my $COMMAND_HELP_CROSS = join "\n", @{ $COMMAND_HELP->{cross} };


my $prog_name   = File::Basename::basename($0);
my $short_usage = "${prog_name} [-D <FILE>] [-P <FILE>] [-F|-N] [-m <msg>] [-n] <CMD> [<ARG>...]";
my $usage       = <<"EOF";
${NAME} (${VERSION}) - ${DESC}

Usage:
  ${short_usage}
  ${prog_name} -h

Options:
  -D, --dict <FILE>         names dictionary
  -F, --files               treat positional arguments as files
  -h, --help                print this help message and exit
  -m, --message <MSG>       comment message for various commands
  -N, --names               treat positional arguments as names
  -n, --dry-run             do not write database
  -P, --pool <FILE>         pool of acquired names

Commands operating on the names dictionary:
${COMMAND_HELP_DICT}

Commands operating on the acquired names pool:
${COMMAND_HELP_POOL}

Commands operating on both the dictionary and the pool:
${COMMAND_HELP_CROSS}

Positional Arguments:
  ARG...                    names or files, depending on -N/-F or command
EOF

sub get_default_dict_file { return './names_dict'; }
sub get_default_pool_file { return './names_pool'; }

sub output_names_to_stdout {
    my $names = shift;

    foreach my $name (@$names) {
        say {*STDOUT} $name;
    }

    return 1;
}


# main ( **@ARGV )
sub main {
    my $ret;

    # parse args
    my $posarg_mode     = undef;
    my $dict_file       = undef;
    my $pool_file       = undef;
    my $want_help       = 0;
    my $want_dry_run    = 0;
    my $comment         = undef;

    my $arg_cmd         = undef;
    my $cmd             = undef;
    my $cmd_short       = undef;
    my $cmd_name        = undef;

    my $need_dict       = 0;
    my $need_pool       = 0;

    my $names_dict      = undef;
    my $names_pool      = undef;
    my $argv_names      = NamesList->new();
    my @argv_parsed;

    if (
        ! GetOptions (
            'D|dict=s'      => \$dict_file,
            'F|files'       => sub { $posarg_mode = 'F'; },
            'h|help'        => \$want_help,
            'm|message=s'   => \$comment,
            'N|names'       => sub { $posarg_mode = 'N'; },
            'n|dry-run'     => \$want_dry_run,
            'P|pool=s'      => \$pool_file
        )
    ) {
        say {*STDERR} 'Usage: ', $short_usage or die "!$\n";
        return 1;  # FIXME EX_USAGE
    }

    # help => exit
    if ( $want_help ) {
        # newline at end supplied by $usage
        print $usage or die "!$\n";
        return 0;
    }

    $arg_cmd = shift @ARGV;
    if ( not $arg_cmd ) {
        die "missing command";
    } else {
        $cmd = $COMMAND_TABLE->{$arg_cmd};
        die "unknown command: ${arg_cmd}\n" unless (defined $cmd);
    }

    $cmd_short = $cmd->{short};
    $cmd_name  = $cmd->{name};

    if ( defined $cmd->{num_posargs} ) {
        if ( $cmd->{num_posargs} == 0 ) {
            # override cmdline posarg mode
            $posarg_mode = undef;
        }

        if ( scalar @ARGV > $cmd->{num_posargs} ) {
            die "command ${cmd_name}: too many positional arguments.\n";
        }
    }

    if ( exists $cmd->{force_posarg_mode} ) {
        $posarg_mode = $cmd->{force_posarg_mode};
    } else {
        $posarg_mode //= $cmd->{default_posarg_mode};   # possibly undef // undef
    }

    if ( $posarg_mode ) {
        if ( $posarg_mode eq 'N' ) {
            if ( scalar @ARGV ) {
                $argv_names->extend ( @ARGV ) or die "invalid input names";
            } else {
                die "command ${cmd_name} (-N): at least one argument required.\n";
            }

            if ( ! scalar @$argv_names ) {
                say {*STDERR} "Nothing to do.";
                return 0;
            }

        } elsif ( $posarg_mode eq 'F' ) {
            if ( scalar @ARGV ) {
                foreach my $infile ( @ARGV ) {
                    open my $infh, '<', $infile or die "Failed to open file: ${infile}: $!\n";
                    $argv_names->read_fh ( $infh ) or die;
                    close $infh or warn;
                }

            } else {
                $argv_names->read_fh ( *STDIN ) or die;
            }

            if ( ! scalar @$argv_names ) {
                say {*STDERR} "Nothing to do.";
                return 0;
            }

        } elsif ( $posarg_mode eq 'uint' ) {
            if ( scalar @ARGV ) {
                foreach (@ARGV) {
                    die "invalid number" unless /^[0-9]+$/mx;
                    push @argv_parsed, $_;
                }
            }

        } else {
            die "invalid posarg mode: ${posarg_mode}";
        }
    }

    if ( $cmd->{need_dict} ) {
        $dict_file //= get_default_dict_file();

        $names_dict = NamesDict->new (
            NamesFlatFileDB->new ( $dict_file )
        );
        $names_dict->{db}->load() or die;
    }

    if ( $cmd->{need_pool} ) {
        $pool_file //= get_default_pool_file();

        $names_pool = NamesPool->new (
            NamesFlatFileDB->new ( $pool_file ),
            $names_dict     # possibly undef
        );
        $names_pool->{db}->load() or die;
    }

    if ( $cmd_short eq 'A' ) {
        $names_dict->do_add ( $argv_names, $comment );

    } elsif ( $cmd_short eq 'B' ) {
        $names_dict->do_ban ( $argv_names, $comment );

    } elsif ( $cmd_short eq 'D' ) {
        $names_dict->do_drop ( $argv_names );

    } elsif ( $cmd_short eq 'P' ) {
        my $names = $names_dict->get_available_names();

        output_names_to_stdout ( $names );

    } elsif ( $cmd_short eq 'f' ) {
        $names_pool->do_free();

    } elsif ( $cmd_short eq 'g' ) {
        my $num_entries = $argv_parsed[0] || 1;
        my $new_names = $names_pool->do_get ( $num_entries, $comment );

        output_names_to_stdout ( $new_names ) or die;

    } elsif ( $cmd_short eq 'o' ) {
        my $names = $names_pool->get_orphaned_names();

        output_names_to_stdout ( $names ) or die;

    } elsif ( $cmd_short eq 'p' ) {
        my $names = $names_pool->get_taken_names();

        output_names_to_stdout ( $names ) or die;

    } elsif ( $cmd_short eq 'r' ) {
        $names_pool->do_release ( $argv_names, $comment );

    } elsif ( $cmd_short eq 't' ) {
        $names_pool->do_take ( $argv_names, $comment );

    } elsif ( $cmd_short eq 'u' ) {
        my $names = $names_pool->get_unused_names();

        output_names_to_stdout ( $names );

    } elsif ( $cmd_short eq 'w' ) {
        $names_pool->do_wipe ( $argv_names, $comment );

    } elsif ( $cmd_short eq 'x' ) {
        $names_pool->do_import ( $argv_names, $comment );

    } else {
        die "command not implemented: ${cmd_name}\n";
    }

    if ( $want_dry_run ) {
        say {*STDERR} 'Discarding changes due to dry run.';

    } else {
        if ( defined $names_dict ) { $names_dict->{db}->commit(); }
        if ( defined $names_pool ) { $names_pool->{db}->commit(); }
    }

    return 0;
}


exit main();


BEGIN {
    package NamesUtil;

    use strict;
    use warnings;

    our $NAMES_MAX_LEN = 63;    # min len enforced via regexp

    our $NAMES_REGEXP = qr/^(?:[a-z0-9]+(?:-[a-z0-9]+)*)$/mx;
    # stem     := words not ending in a number, separated by a hyphen
    #             (COULDFIX: only last word must not end with a number)
    #          := <wordlist>
    # wordlist := <word>
    # wordlist := <word> <wordlist>
    # suffix   := ["-"] <id>
    # id       := number
    #
    our $_NAMES_STEM_REGEXP = qr/(?<stem>(?:[a-z]+(?:[0-9]*[a-z]+)*)(?:(?:[0-9]*-[a-z]+(?:[0-9]*[a-z]+)*)*))/mx;
    our $_NAMES_SUFFIX_REGEXP = qr/(?<suffix>-?(?<id>[0-9]+))/mx;

    our $NAMES_STEMSPLIT_REGEXP = qr/^${_NAMES_STEM_REGEXP}${_NAMES_SUFFIX_REGEXP}$/mx;

    sub normalize_name {
        my $pat = $NAMES_REGEXP;
        my $arg;
        my $name;

        $arg = shift;

        if ( length $arg > $NAMES_MAX_LEN ) {
            return;
        }

        $name = (lc $arg);

        if ( $name =~ /$pat/ ) {
            return $name;

        } else {
            return;
        }
    }

    sub split_stem {
        my $pat = $NAMES_STEMSPLIT_REGEXP;
        my $arg;

        $arg = shift;

        if ( $arg =~ $NAMES_STEMSPLIT_REGEXP ) {
            return $+{stem};
        } else {
            return;
        }
    }


    package NamesList;

    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $self  = [];

        return bless $self, $class;
    }

    sub append {
        my ( $self, $arg ) = @_;
        my $name;

        $name = NamesUtil::normalize_name ( $arg );
        if ( $name ) {
            push @$self, $name;
            return 1;
        } else {
            return 0;
        }
    }

    sub extend {
        my $self = shift;

        foreach my $arg (@_) {
            $self->append ( $arg ) or return 0;
        }

        return 1;
    }

    sub read_fh {
        local $_ = undef;

        my $self = shift;
        my $fh = shift;

        while (<$fh>) {
            # str_strip()
            s/^\s+//mx;
            s/\s+$//mx;

            # skip empty and comment lines
            if ( /^[^#]/mx ) {
                $self->append ( $_ ) or return 0;
            }
        }

        return 1;
    }

    package NamesDBEntry;

    use strict;
    use warnings;
    use feature qw( say );

    sub new {
        my $class = shift;
        my $self  = {
            status  => shift,
            name    => shift,
            comment => shift
        };

        return bless $self, $class;
    }


    package AbstractNamesFlatFileDB;

    use strict;
    use warnings;
    use feature qw( say );

    sub new {
        my $class = shift;
        my $self  = {
            _filepath => shift,
            _dirty    => undef,
            _entries  => undef
        };

        return bless $self, $class;
    }

    sub _load_entries {
        my $self = shift;
        my $filepath = shift;

        die unless $filepath;
        die "abc: method not implemented: _load_entries()\n";
    }

    sub _write_entries {
        my $self = shift;
        my $filepath = shift;
        my $entries = shift;

        die unless $filepath;
        die "abc: method not implemented: _write_entries()\n";
    }

    sub load {
        my $self = shift;
        my $entries;

        $entries = $self->{_entries};
        if ( not defined $entries ) {
            $entries = $self->_load_entries ( $self->{_filepath} );

            if ( not defined $entries ) {
                $entries = {};
            }

            $self->{_entries} = $entries;
            $self->{_dirty} = 0;
        }

        return 1;
    }

    sub get_entries {
        my $self = shift;

        return $self->{_entries};
    }

    sub get_entry {
        my $self = shift;
        my $key = shift;

        my $entries = $self->get_entries();

        return $entries->{$key};
    }

    sub mark_as_dirty {
         my $self = shift;
         $self->{_dirty} = 1;

         return 1;
    }

    sub write_file {
        my $self = shift;

        die unless (defined $self->{_entries});

        $self->_write_entries ( $self->{_filepath}, $self->{_entries} );
        $self->{_dirty} = 0;

        return 1;
    }

    sub commit {
        my $self = shift;

        if ( (defined $self->{_entries}) && $self->{_dirty} ) {
            return $self->write_file();
        } else {
            return 1;
        }
    }


    package NamesFlatFileDB;

    use strict;
    use warnings;
    use feature qw( say );

    use IO::Uncompress::Gunzip;
    use IO::Compress::Gzip;

    @NamesFlatFileDB::ISA = qw( AbstractNamesFlatFileDB );

    sub _load_entries_from_fh {
        local $_ = undef;

        my $self = shift;
        my $fh = shift;
        my $entries = {};

        while (<$fh>) {
            # str_strip()
            s/^\s+//mx;
            s/\s+$//mx;

            # skip empty and comment lines
            #  Note that comment lines will be lost on rewrite
            if ( /^[^#]/mx ) {
                my @fields  = split /\|/mx, $_, 3;
                my $nfields = scalar @fields;

                if ( $nfields != 3 ) { die "file format error\n"; }
                # <status> <name> <comment>
                die "file data error\n" unless ( $fields[0] =~ /^[0-9]+$/mx );
                die "file data error\n" unless ( $fields[1] );

                my $entry = NamesDBEntry->new (
                        (0 + $fields[0] ),                  # status
                        $fields[1],                         # name
                        ($fields[2]) ? $fields[2] : undef   # comment
                );
                my $key = $entry->{name};

                # in case of duplicates, most recently read entry wins
                $entries->{$key} = $entry;
            }
        }

        return $entries;
    }

    sub _write_entries_to_fh {
        my $self = shift;
        my $fh = shift;
        my $entries = shift;

        foreach my $key ( sort keys %$entries ) {
            my $entry = $entries->{$key};
            my $s = join '|', $entry->{status}, $entry->{name}, ($entry->{comment} // '');

            say {$fh} $s or die;
        }

        return 1;
    }

    sub _load_entries {
        my $self = shift;
        my $filepath = shift;
        die unless $filepath;

        my $filepath_gz = $filepath . '.gz';

        my $entries;
        my $fh = undef;

        if ( -f $filepath_gz ) {
            $fh = IO::Uncompress::Gunzip->new ( $filepath_gz );
        }

        if ( $fh ) {
            ;

        } elsif ( open $fh, '<', $filepath ) {
            ;

        } elsif ( $!{ENOENT} ) {
            return;

        } else {
            die "Failed to open file: $!\n";
        }

        $entries = $self->_load_entries_from_fh($fh);
        close $fh or warn;
        return $entries;
    }

    sub _write_entries {
        my $self = shift;
        my $filepath = shift;
        my $entries = shift;
        die unless $filepath;

        my $fh;
        my $filepath_new    = $filepath . '.new';
        my $filepath_gz     = $filepath . '.gz';
        my $filepath_gz_new = $filepath_gz . '.new';
        my $gz_status;

        open $fh, '>', $filepath_new or die;
        $self->_write_entries_to_fh ( $fh, $entries );
        close $fh or warn;

        $gz_status = IO::Compress::Gzip::gzip $filepath_new => $filepath_gz_new;

        $self->_rotate_outfile ( $filepath_new, $filepath ) or die "Failed to write db!\n";

        # unlink old gz after writing db
        #  this might result in outdated gz files,
        #  but ensures that the db file always exists,
        #  even if it previously existed as .gz only
        unlink $filepath_gz;

        if ( $gz_status ) {
            $self->_rotate_outfile ( $filepath_gz_new, $filepath_gz ) or die "Failed to write gzip db!\n";
        }

        return 1;
    }

    sub _rotate_outfile {
        my $self = shift;
        my $filepath_new = shift;
        my $filepath = shift;

        my $filepath_bak = $filepath . '.old';

        unlink $filepath_bak or $!{ENOENT} or die;

        rename $filepath, $filepath_bak or $!{ENOENT} or die;

        unless ( rename $filepath_new, $filepath ) {
            my $err = $!;
            rename $filepath_bak, $filepath or die;
            die "failed to move new db file: ${err}\n";
        }

        return 1;
    }


    package _Names;

    use strict;
    use warnings;
    use feature qw( say );

    use constant {
        KEEP_STATUS     => undef,

        STATUS_ACTIVE   => 1,
        STATUS_INACTIVE => 2,
    };

    sub new {
        my $class = shift;
        my $self  = {
            db => shift
        };

        return bless $self, $class;
    }

    sub has {
        my $self = shift;
        my $name = shift;

        return ( defined $self->{db}->get_entry($name) );
    }

    sub check_transition {
        my $self = shift;
        my $src  = shift;
        my $dst  = shift;

        my $tt = $self->{transitions}->{$src};

        if ( defined $tt ) {
            if ( $tt->{$dst} ) {
                return 1;
            } else {
                return 0;   # even if explicitly set to undef
            }

        } elsif ( exists $self->{transitions}->{$src} ) {
            # explicit "<status> => undef" --> allow all
            return 1;

        } else {
            # entry missing
            return 0;
        }
    }

    sub get_transition_err {
        my $self = shift;
        my $src_entry = shift;
        my $dst = shift;

        return (
            sprintf
                "entry %s: invalid transition: %d -> %d",
                $src_entry->{name},
                $src_entry->{status},
                $dst
        );
    }

    sub get_entries_hash {
        my $self = shift;

        return $self->{db}->get_entries();
    }

    # get_entries ( self, status, want_sort )
    sub get_entries {
        my ( $self, $status, $want_sort ) = @_;
        my $all_entries_ref;
        my @entries;

        $all_entries_ref = $self->get_entries_hash();
        @entries = values %$all_entries_ref;

        if ( defined $status ) {
            @entries = grep { $_->{status} == $status } @entries;
        }

        if ( $want_sort ) {
            @entries = sort { $a->{name} cmp $b->{name} } @entries;
        }

        return \@entries;
    }

    # get_names ( self, ... ) -> [e.name for e in get_entries(...)]
    sub get_names {
        my $self = shift;
        my $entries_ref;
        my @names;

        $entries_ref = $self->get_entries ( @_ );

        @names = map { $_->{name}; } @$entries_ref;

        return \@names;
    }

    sub _add_names {
        my $self = shift;
        my $names = shift;
        my $status = shift;
        my $comment = shift;

        if ( scalar @$names ) {
            my $entries = $self->get_entries_hash();

            $self->{db}->mark_as_dirty();

            foreach my $name (@$names) {
                $entries->{$name} = NamesDBEntry->new ( $status, $name, $comment );
            }
        }

        return 1;
    }

    sub _update_entries {
        my $self = shift;
        my $entries = shift;
        my $status = shift;
        my $comment = shift;

        if ( scalar @$entries ) {
            if ( defined $status ) {
                $self->{db}->mark_as_dirty();

                foreach my $entry (@$entries) {
                    $entry->{status} = $status;
                }
            }

            if ( defined $comment ) {
                $self->{db}->mark_as_dirty();

                foreach my $entry (@$entries) {
                    $entry->{comment} = $comment;
                }
            }
        }

        return 1;
    }

    sub _delete_names {
        my $self = shift;
        my $names = shift;

        my $all_entries = $self->get_entries_hash();

        if ( scalar @$names ) {
            $self->{db}->mark_as_dirty();

            foreach my $name (@$names) {
                delete $all_entries->{$name};
            }
        }

        return 1;
    }

    sub add_names {
        my $self = shift;
        my $names = shift;
        my $status = shift;
        my $comment = shift;
        my $only_new = shift;

        my $entries = $self->get_entries_hash();

        my @names_to_add;
        my @entries_to_update;

        my $ret = 1;

        die unless (defined $status);

        foreach my $name (@$names) {
            my $entry = $entries->{$name};

            if ( not defined $entry ) {
                push @names_to_add, $name;

            } elsif ( $only_new ) {
                die "entry ${name} already exists, cannot add.\n";
                return 0;   # unreachable

            } else {
                if ( ! $self->check_transition ( $entry->{status}, $status ) ) {
                    die $self->get_transition_err ( $entry, $status );

                } elsif ( ${entry}->{status} != $status ) {
                    push @entries_to_update, $entry;
                    $ret = 3;

                } else {
                    warn "entry ${name} already exists, skipping.\n";
                    $ret = 2;
                }
                # else no-op

            }
        }

        if ( scalar @names_to_add ) {
            $self->_add_names ( \@names_to_add, $status, $comment ) or die;
        }

        if ( scalar @entries_to_update ) {
            $self->_update_entries ( \@entries_to_update, $status, $comment ) or die;
        }

        return $ret;
    }

    sub update_entries {
        my $self = shift;
        my $entries = shift;
        my $status = shift;
        my $comment = shift;

        my @entries_to_update;

        die unless (defined $status);

        foreach my $entry (@$entries) {
            # comment not considered here <=> update comment IFF new status
            if ( ! $self->check_transition ( $entry->{status}, $status ) ) {
                die $self->get_transition_err ( $entry, $status );

            } elsif ( $entry->{status} != $status ) {
                push @entries_to_update, $entry;
            }
            # else no-op
        }

        if ( scalar @entries_to_update ) {
            $self->_update_entries ( $entries, $status, $comment ) or die;
        }

        return 1;
    }

    sub update_names {
        my $self = shift;
        my $names = shift;
        my $status = shift;
        my $comment = shift;

        my $ret = 1;

        my $all_entries = $self->get_entries_hash();

        my @entries;

        foreach my $name (@$names) {
            my $entry = $all_entries->{$name};

            if ( defined $entry ) {
                push @entries, $all_entries->{$name};

            } else {
                warn "entry ${name} does not exist, skipping.\n";
                $ret = 2;
            }
        }

        $self->update_entries ( \@entries, $status, $comment ) or die;

        return $ret;
    }

    sub delete_names {
        my $self = shift;
        my $names = shift;

        my $all_entries = $self->get_entries_hash();

        my @names_to_del;

        my $ret = 1;

        foreach my $name (@$names) {
            if ( defined $all_entries->{$name} ) {
                push @names_to_del, $name;

            } else {
                warn "entry ${name} does not exist, skipping.\n";
                $ret = 2;
            }
        }

        $self->_delete_names ( \@names_to_del ) or die;

        return $ret;
    }


    package NamesDict;

    use strict;
    use warnings;
    use feature qw( say );

    @NamesDict::ISA = qw( _Names );

    use constant {
        STATUS_AVAIL => _Names::STATUS_ACTIVE,
        STATUS_BAN   => _Names::STATUS_INACTIVE,
    };

    my $NAMES_DICT_TRANSITION_TABLE = {
        STATUS_AVAIL() => {
            STATUS_AVAIL() => 1,
            STATUS_BAN()   => 1,
        },

        STATUS_BAN() => {
            STATUS_AVAIL() => 0,
            STATUS_BAN()   => 1,
        },
    };

    sub new {
        my $class = shift;
        my $db = shift;
        my $names_dict = shift;

        my $self = $class->SUPER::new($db);

        $self->{transitions} = $NAMES_DICT_TRANSITION_TABLE;

        return bless $self, $class;
    }

    sub get_available_names {
        my $self = shift;
        return $self->get_names ( STATUS_AVAIL, 1 );
    }

    sub get_banned_names {
        my $self = shift;
        return $self->get_names ( STATUS_BAN, 1 );
    }

    sub do_add {
        my $self = shift;
        my $names = shift;
        my $comment = shift;

        return $self->add_names ( $names, STATUS_AVAIL, $comment, 0 );
    }

    sub do_ban {
        my $self = shift;
        my $names = shift;
        my $comment = shift;

        return $self->update_names ( $names, STATUS_BAN, $comment );
    }

    sub do_drop {
        my $self = shift;
        my $names = shift;

        return $self->delete_names ( $names );
    }

    package NamesPool;

    use strict;
    use warnings;
    use feature qw( say );

    use List::Util;

    @NamesPool::ISA = qw( _Names );

    use constant {
        STATUS_TAKEN  => _Names::STATUS_ACTIVE,
        STATUS_UNUSED => _Names::STATUS_INACTIVE,
    };

    my $NAMES_POOL_TRANSITION_TABLE = {
        STATUS_TAKEN() => {
            STATUS_TAKEN()  => 1,
            STATUS_UNUSED() => 1,
        },

        STATUS_UNUSED() => {
            STATUS_TAKEN()  => 1,
            STATUS_UNUSED() => 1,
        },
    };

    sub new {
        my $class = shift;
        my $db = shift;
        my $names_dict = shift;

        my $self = $class->SUPER::new($db);

        $self->{transitions} = $NAMES_POOL_TRANSITION_TABLE;

        $self->{dict} = $names_dict;

        return bless $self, $class;
    }

    sub get_taken_names {
        my $self = shift;
        return $self->get_names ( STATUS_TAKEN, 1 );
    }

    sub get_unused_names {
        my $self = shift;
        return $self->get_names ( STATUS_UNUSED, 1 );
    }

    sub get_orphaned_names {
        my $self = shift;

        my $dict_entries = $self->{dict}->get_entries_hash();
        my $names = $self->get_names ( undef, 1 );

        my @orphans;

        @orphans = grep { not defined $dict_entries->{$_} } @$names;

        return \@orphans;
    }

    sub do_release {
        my $self = shift;
        my $names = shift;
        my $comment = shift;

        return $self->update_names ( $names, STATUS_UNUSED, $comment );
    }

    sub _check_take {
        my $self = shift;
        my $names = shift;

        my $entries = $self->{db}->get_entries();
        my $dict_entries = $self->{dict}->{db}->get_entries();

        my %names_to_add;
        my %names_to_update;
        my %names_taken;
        my %names_missing;

        foreach my $name (@$names) {
            if ( exists $entries->{$name} ) {

                if ( $entries->{$name}->{status} == STATUS_TAKEN ) {
                    $names_taken{$name} = 1;

                } else {
                    $names_to_update{$name} = 1;
                }

            } elsif ( exists $dict_entries->{$name} ) {
                $names_to_add{$name} = 1;

            } else {
                # try harder
                my $stem = NamesUtil::split_stem ( $name );

                if ( $stem ) {
                    if ( exists $dict_entries->{$stem} ) {
                        # should also take $stem if not already done
                        if ( not exists $entries->{$stem} ) {
                            $names_to_add{$stem} = 1;
                        }

                        $names_to_add{$name} = 2;

                    } else {
                        $names_missing{$stem} = 1;
                        $names_missing{$name} = 2;
                    }

                } else {
                    $names_missing{$name} = 1;
                }
            }
        }

        return \%names_to_add, \%names_to_update, \%names_taken, \%names_missing;
    }

    sub do_take {
        my $self = shift;
        my $names = shift;
        my $comment = shift;

        my (
            $names_to_add, $names_to_update, $names_taken, $names_missing
        )  = $self->_check_take ( $names );

        my $fail = 0;
        my $ret_add;
        my $ret_update;

        if ( scalar %$names_taken ) {
            $fail = 1;
            warn 'Names already taken: ' . (join ', ', sort keys %$names_taken) . "\n";
        }

        if ( scalar %$names_missing ) {
            $fail = 1;
            warn 'Names missing: ' . (join ', ', sort keys %$names_missing) . "\n";
        }

        if ( $fail ) {
            die "cannot claim names.\n";
        }

        if ( scalar %$names_to_add ) {
            my @to_add = keys %$names_to_add;

            $ret_add = $self->add_names ( \@to_add, STATUS_TAKEN, $comment, 1 );
            if ( $ret_add != 1 ) { return $ret_add; }

        } else {
            $ret_add = 1;
        }

        if ( scalar %$names_to_update ) {
            my @to_update = keys %$names_to_update;

            $ret_update = $self->update_names ( \@to_update, STATUS_TAKEN, $comment );
            if ( $ret_update < 1 ) { return $ret_update; }

        } else {
            $ret_update = 1;
        }

        return ($ret_update > $ret_add) ? $ret_update : $ret_add;
    }

    sub do_import {
        my $self = shift;
        my $names = shift;
        my $comment = shift;

        my (
            $names_to_add, $names_to_update, $names_taken, $names_missing
        )  = $self->_check_take ( $names );

        my $ret_add;
        my $ret_update;

        if ( scalar %$names_taken ) {
            warn 'Names already taken: ' . (join ', ', sort %$names_taken) . "\n";
            # but continue
        }

        if ( scalar %$names_missing ) {
            my @to_add_to_dict = grep { $names_missing->{$_} == 1 } keys %$names_missing;

            if ( scalar @to_add_to_dict ) {
                $ret_add = $self->{dict}->do_add ( \@to_add_to_dict );
                if ( $ret_add < 1 ) { die "Failed to add new names to dict.\n"; }
            }

            foreach my $name ( keys %$names_missing ) {
                $names_to_add->{$name} = $names_missing->{$name};
            }
        }

        if ( scalar %$names_to_add ) {
            my @to_add = keys %$names_to_add;

            $ret_add = $self->add_names ( \@to_add, STATUS_TAKEN, $comment, 1 );
            if ( $ret_add != 1 ) { return $ret_add; }

        } else {
            $ret_add = 1;
        }

        if ( scalar %$names_to_update ) {
            my @to_update = keys %$names_to_update;

            $ret_update = $self->update_names ( \@to_update, STATUS_TAKEN, $comment );
            if ( $ret_update < 1 ) { return $ret_update; }

        } else {
            $ret_update = 1;
        }

        return ($ret_update > $ret_add) ? $ret_update : $ret_add;
    }

    sub do_peek {
        my $self = shift;
        my $num_names = shift // 1;

        my $entries = $self->{db}->get_entries();

        my $all_names;
        my @candidates_new;
        my @cand;
        my @names;

        $all_names = $self->{dict}->get_names ( STATUS_TAKEN );

        foreach my $name ( @$all_names ) {
            if ( not exists $entries->{$name} ) {
                push @candidates_new, $name;
            }
        }

        @cand = List::Util::shuffle ( @candidates_new );

        while ( $num_names > 0 ) {
            my $name = shift @cand;
            if ( $name ) {
                push @names, $name;
                $num_names--;
            } else {
                last;
            }
        }

        # candidates ~ released

        if ( $num_names > 0 ) {
            return;
        } else {
            return \@names;
        }
    }

    sub do_free {
        my $self = shift;
        my $entries = $self->{db}->get_entries();

        my @keys_to_delete;

        foreach my $key (keys %$entries) {
            my $entry = $entries->{$key};

            if ( $entry->{status} == STATUS_UNUSED ) {
                push @keys_to_delete, $key;
            }
        }

        if ( scalar @keys_to_delete ) {
            $self->{db}->mark_as_dirty();

            foreach my $key (@keys_to_delete) {
                delete $entries->{$key};
            }

            return 1;

        } else {
            return 2;
        }
    }

    sub do_get {
        my $self = shift;
        my $num_names = shift;
        my $comment = shift;

        my $names = $self->do_peek ( $num_names );
        die "not enough free names available.\n" unless (defined $names);

        my $ret = $self->add_names ( $names, STATUS_TAKEN, $comment, 1 );
        die "failed to take names.\n" unless ( $ret == 1 );

        return $names;
    }

    sub do_wipe {
        my $self = shift;
        my $names = shift;

        return $self->delete_names ( $names );
    }

}
