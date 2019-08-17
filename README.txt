names (0.2) - make a name for yourself

  Manages a pool of names.

  The typical workflow is to import a bulk of (host)names into a "dictionary"
  once and then repeatedly retrieve random names from the dictionary
  and add them to your "pool". You may annotate names with comments
  describing their purpose or when they were taken (-m option).

  Several pools may share the same dictionary.

  Supported commands include adding and removing names from the dictionary
  or the pool, plus some housekeeping like listing taken names.

  Names follow hostname restrictions, which is the intended use case.
  N name may be longer than 63 chars and must match some regexp fu.

  Names can be given on the cmdline or read from files,
  which can be controlled with the -N and -F switches.
  The default mode depends on the command
  (see the (N) or (F) suffix in description below).

  When claiming a name for the pool with the 'take' command,
  it has to exist in the dictionary.
  Failing that, if the requested name ends in a sequence of digits,
  optionally preceeded by a hyphen character,
  its basename must exist in the dictionary.
  For example, the names "foo-1", "foo1", "foo-002"
  would all be looked up as-is and then as "foo".
  Names like "bar1-1" are excluded from this logic.

  Names present in the pool should also exist in the dictionary,
  however this is not strictly enforced in all cases,
  e.g. when switching between dictionaries.

  Since importing a huge bulk of names into the dictionary imposes faint
  control over individual words, the dictionary may contain names
  that make you feel uncomfortable one way or another.
  Such names can be banned. They then remain in the dictionary
  but get marked as do-not-use so that they can not be readded by mistake.
  Banned names remain in pool databases if already taken there.

  If a database has been modified, its new file is written to <file>.new.
  The original file is moved to <file>.old prior to putting the new file
  in place. In git mode (see below), the old file gets deleted after
  checking the new files in.

  The program offers some convenience helpers:

    - copy to clipboard
      For get and print commands, also copy the names to both the primary
      and the clipboard selection, provided that the DISPLAY environment
      variable is set and xclip(1) is installed.

    - git mode
      For commands modifying the dict or pool database files,
      track changes with git-add and git-commit,
      optionally reusing the comment message (-m option).

      This also restricts dict database file paths to <git topdir>/db/dict
      and pool database file paths to <git topdir>/db/pool. Relative paths
      starting with ./ are looked in the current working directory.

      Git mode is automatically enabled if your current working directory
      is part of a git repository.
      This behavior can be overridden with the --git/--no-git option,
      it also gets disabled by the --root option.


Usage:
  names.pl {-c|-D <FILE>|-F|-g|-h|-m <MSG>|-N|-n|-P <FILE>|-R <DIR>|-v} <CMD> {<ARG>}
  names.pl -h

Options:
  -c, --clipboard           copy output to clipboard (using xclip)
  -D, --dict <DICT>         names dictionary file
  -F, --files               treat positional arguments as files
  -g, --git                 git-add and commit changed db files,
                            restrict file paths to git topdir
                            deduced from current working directory
                            (default: autodetect)
  --no-git                  force no-git mode
  -h, --help                print this help message and exit
  -m, --message <MSG>       comment message for various commands
  -N, --names               treat positional arguments as names
  -n, --dry-run             do not write database
  -P, --pool <POOL>         pool of acquired names file
  -R, --root <ROOT>         look up dict and pool files in <ROOT>:
                              <ROOT>/db/dict/<DICT> (DICT:="default")
                              <ROOT>/db/pool/<POOL> (POOL:="default")
                              This is not a security feature,
                              relative paths may be used to escape <ROOT>.
                              Disables git mode.
  -v, --verbose             print debug information

Commands operating on the names dictionary:
  A, add ...               add names (F)
  B, ban ...               ban names (N)
  D, drop ...              delete names (F)
  P, print-db              print names

Commands operating on the acquired names pool:
  f, free                  remove unused names
  g, get <ARG>             acquire a new random name (uint)
  o, orphaned              print orphaned names (present in pool but not dict)
  p, print                 print acquired names
  r, release ...           mark names as unused (N)
  t, take ...              register names as acquired (N)
  u, unused                print unused names
  w, wipe ...              remove names so that they may be reacquired (N)

Commands operating on both the dictionary and the pool:
  x, import ...            register a name as acquired if new, add to dict if new (N)
                               for names matching stem/suffix,
                               add only new stems to dict

Positional Arguments:
  ARG...                    names or files, depending on -N/-F or command

BUGS
  names.pl uses a flat-file database.
  While this keeps dependencies light, it has some deficiencies.

  Since names.pl loads the entire database into memory,
  it gets slower and consumes more memory with increasing dict and pool sizes.
  Operations on a mostly empty names pool backed by a 20k names dict take
  about 0.3s, whereas ops on a fully occupied 100k names pool take between 1-2s.

  Do not hardlink the database files, they get rotated on write operations.
