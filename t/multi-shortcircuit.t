#!perl
use strict;
use warnings;

use Test::More;
use Test::Warnings 0.005 qw[ warning ];
use Test::Fatal;

use Getopt::Long::Descriptive;

# Check which of a set of shortcircuit options is used
my @alts = my @names = qw(help man ver);
for my $name ( @names ) {
  my($opt, $usage);
  my $error = exception {
    local @ARGV = ('--flag', "--$name" );
    ($opt, $usage) = describe_options(
      '%c %o',
      [ 'flag', 'flag' ],
      [ 'help', 'help', { shortcircuit => 1 } ],
      [ 'man', 'man', { shortcircuit => 1 } ],
      [ 'ver', 'ver', { shortcircuit => 1 } ],
    );
  };
  is $error, undef, "$name: no error";
  ok !$opt->flag, "$name: no flag";
  for my $alt ( @alts ) {
    if ( $alt eq $name ) {
      ok $opt->$alt, "$name: got $alt";
    }
    else {
      ok !$opt->$alt, "$name: no $alt";
    }
  }
}

# Make sure that any but only one shortcircuit option is used
# and that no required checks are done iff shortcircuiting

# the ver(sion) option may or may not be a shortcircuit option
sub _opts {
  return (
    '%c %o',
    [ 'req',  'required', { required     => 1 } ],
    [ 'help', 'help',     { shortcircuit => 1 } ],
    [ 'ver',  'version',  { shortcircuit => ( $_[0] || 0 ) } ],
  );
}

my @tests = (

  #1  - only help shortcircuits and is unused.
  #   - req is used.
  { argv => [qw( --req --ver 0 )],    # 0 = ver does not shotcircuit
    opts => [qw( 0 )],                # arguments to _opts
    like => undef,                    # the error/exception matches this if any
    got  => {                         # option values
      req  => 1,
      help => undef,
      ver  => 1,
    },
  },

  #2  - only help shortcircuits and is used
  #   - no req should be ok
  { argv => [qw( --help --ver 0 )],
    opts => [],
    like => undef,
    got  => {
      req  => undef,
      help => 1,
      ver  => undef,
    },
  },

  #3  - ver shortcircuits and is used
  #   - help is not used so using ver should be ok
  #   - no req should be ok
  { argv => [qw( --ver 1 )],
    opts => [qw( 1 )],         # ver shortcircuits
    like => undef,
    got  => {
      req  => undef,
      help => undef,
      ver  => 1,
    },
  },

  #4  all three are used AND ver shortcircuits so this dies
  { argv => [qw( --req --help --ver 1 )],
    opts => [qw( 1 )],
    like => qr/are mutually exclusive/,
    got  => {
      req  => undef,
      help => undef,
      ver  => undef,
    },
  },

  #5  Make sure no options at all errors because of req.
  { argv => [qw(no options)],
    opts => [],
    like => qr/Mandatory parameter 'req' missing/,
    got  => {
      req => undef,
      help => undef,
      ver => undef,
    },
  },
);

for my $test (@tests) {

  # Unpack the parameters
  my ( $argv, $opts, $like, $got )
      = @{$test}{qw(argv opts like got)};

  # set inside the exception block
  my ( $opt, $usage );

  # the main action
  my $error = exception {
    local @ARGV = @$argv;
    ( $opt, $usage ) = describe_options( _opts(@$opts) );
  };

  # do we expect any error?
  if ($like) {    # yes we do
    like $error, $like, "@$argv: error";
    is $opt, undef, "@$argv: no opt";
  }
  else {          # no error expected
    is $error, undef, "@$argv: no error";
    ok ref($opt), "@$argv: got options";

    # inspect the individual options
    for my $name ( sort keys %$got ) {
      my $val = $got->{$name};

      # for the test name
      my $want = defined($val) ? $val : 'undef';
      is $opt->$name, $val, "@$argv: $name is $want";
    }
  }
}

done_testing;
