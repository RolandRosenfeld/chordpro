#! perl

package main;

our $config;
our $options;

package App::Music::ChordPro::Chords;

use strict;
use warnings;
use utf8;

use App::Music::ChordPro::Chords::Parser;

# Chords defined by the configs.
my %config_chords;

# Names of chords loaded from configs.
my @chordnames;

# Additional chords, defined by the user.
my %song_chords;

# Current tuning.
my @tuning;

# Assert that an instrument is loaded.
sub assert_tuning {
    Carp::croak("FATAL: No instrument?") unless @tuning;
}

################ Section Dumping Chords ################

sub chordcompare($$);

# API: Returns a list of all chord names in a nice order.
# Used by: ChordPro, Output/ChordPro.
sub chordnames {
    assert_tuning();
    [ sort chordcompare @chordnames ];
}

# Chord order ordinals, for sorting.
my %chordorderkey; {
    my $ord = 0;
    for ( split( ' ', "C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B" ) ) {
	$chordorderkey{$_} = $ord;
	$ord += 2;
    }
}

# Compare routine for chord names.
# API: Used by: Songbook.
sub chordcompare($$) {
    my ( $chorda, $chordb ) = @_;
    my ( $a0, $arest ) = $chorda =~ /^([A-G][b#]?)(.*)/;
    my ( $b0, $brest ) = $chordb =~ /^([A-G][b#]?)(.*)/;
    $a0 = $chordorderkey{$a0//"\x{ff}"}//return 0;
    $b0 = $chordorderkey{$b0//"\x{ff}"}//return 0;
    return $a0 <=> $b0 if $a0 != $b0;
    $a0++ if $arest =~ /^m(?:in)?(?!aj)/;
    $b0++ if $brest =~ /^m(?:in)?(?!aj)/;
    for ( $arest, $brest ) {
	s/11/:/;		# sort 11 after 9
	s/13/;/;		# sort 13 after 11
	s/\((.*?)\)/$1/g;	# ignore parens
	s/\+/aug/;		# sort + as aug
    }
    $a0 <=> $b0 || $arest cmp $brest;
}
# Dump a textual list of chord definitions.
# Should be handled by the ChordPro backend?

sub list_chords {
    my ( $chords, $origin, $hdr ) = @_;
    assert_tuning();
    my @s;
    if ( $hdr ) {
	my $t = "-" x (((@tuning - 1) * 4) + 1);
	substr( $t, (length($t)-7)/2, 7, "strings" );
	push( @s,
	      "# CHORD CHART",
	      "# Generated by ChordPro " . $App::Music::ChordPro::VERSION,
	      "# https://www.chordpro.org",
	      "#",
	      "#            " . ( " " x 35 ) . $t,
	      "#       Chord" . ( " " x 35 ) .
	      join("",
		   map { sprintf("%-4s", $_) }
		   @tuning ),
	    );
    }

    foreach my $chord ( @$chords ) {
	my $info;
	if ( eval{ $chord->{name} } ) {
	    $info = $chord;
	}
	elsif ( $origin eq "chord" ) {
	    push( @s, sprintf( "{%s:  %s}", "chord", $chord ) );
	    next;
	}
	else {
	    $info = _known_chord($chord);
	}
	next unless $info;
	my $s = sprintf( "{%s %-15.15s base-fret %2d    ".
			 "frets   %s",
			 $origin eq "chord" ? "chord: " : "define:",
			 $info->{name}, $info->{base},
			 @{ $info->{frets} }
			 ? join("",
				map { sprintf("%-4s", $_) }
				map { $_ < 0 ? "X" : $_ }
				@{ $info->{frets} } )
			 : ("    " x strings() ));
	$s .= join("", "    fingers ",
		   map { sprintf("%-4s", $_) }
		   map { $_ < 0 ? "X" : $_ }
		   @{ $info->{fingers} } )
	  if $info->{fingers} && @{ $info->{fingers} };
	$s .= join("", "    keys ",
		   map { sprintf("%2d", $_) }
		   @{ $info->{keys} } )
	  if $info->{keys} && @{ $info->{keys} };
	$s .= "}";
	push( @s, $s );
    }
    \@s;
}

sub dump_chords {
    my ( $mode ) = @_;
    assert_tuning();
    print( join( "\n",
		 $mode && $mode == 2
		 ? @{ json_chords(\@chordnames ) }
		 : @{ list_chords(\@chordnames, "__CLI__", 1) } ), "\n" );
}

sub json_chords {
    my ( $chords ) = @_;
    assert_tuning();
    my @s;

    push( @s, "// ChordPro instrument definition.",
	  "",
	  qq<{ "instrument" : "> .
	  ($::config->{instrument} || "Guitar, 6 strings, standard tuning") .
	  qq<",>,
	  "",
	  qq<  "tuning" : [ > .
	  join(", ", map { qq{"$_"} } @tuning) . " ],",
	  "",
	  qq{  "chords" : [},
	  "",
	 );

    my $maxl = -1;
    foreach my $chord ( @$chords ) {
	my $t = length( $chord );
	$maxl < $t and $maxl = $t;
    }
    $maxl += 2;

    foreach my $chord ( @$chords ) {
	my $info;
	if ( eval{ $chord->{name} } ) {
	    $info = $chord;
	}
	else {
	    $info = _known_chord($chord);
	}
	next unless $info;

	my $name = '"' . $info->{name} . '"';
	my $s = sprintf( qq[    { "name" : %-${maxl}.${maxl}s,] .
                         qq[ "base" : %2d,],
			 $name, $info->{base} );
	if ( @{ $info->{frets} } ) {
	    $s .= qq{ "frets" : [ } .
	      join( ", ", map { sprintf("%2s", $_) } @{ $info->{frets} } ) .
		qq{ ],};
	}
	if ( $info->{fingers} && @{ $info->{fingers} } ) {
	    $s .= qq{ "fingers" : [ } .
	      join( ", ", map { sprintf("%2s", $_) } @{ $info->{fingers} } ) .
		qq{ ],};
	}
	if ( $info->{keys} && @{ $info->{keys} } ) {
	    $s .= qq{ "keys" : [ } .
	      join( ", ", map { sprintf("%2d", $_) } @{ $info->{keys} } ) .
		qq{ ],};
	}
	chop($s);
	$s .= " },";
	push( @s, $s );
    }
    chop( $s[-1] );
    push( @s, "", "  ]," );
    if ( $::config->{pdf}->{diagrams}->{vcells} ) {
	push( @s, qq<  "pdf" : { "diagrams" : { "vcells" : > .
	      $::config->{pdf}->{diagrams}->{vcells} . qq< } },> );
    }
    chop( $s[-1] );
    push( @s, "}" );
    \@s;
}

################ Section Tuning ################

# API: Return the number of strings supported.
# Used by: Songbook, Output::PDF.
sub strings {
    scalar(@tuning);
}

my $parser;# = App::Music::ChordPro::Chords::Parser->default;

# API: Set tuning, discarding chords.
# Used by: Config.
sub set_tuning {
    my ( $cfg ) = @_;
    my $t = $cfg->{tuning} // [];
    return "Invalid tuning (not array)" unless ref($t) eq "ARRAY";
    $options //= { verbose => 0 };

    if ( @tuning ) {
	( my $t1 = "@$t" ) =~ s/\d//g;
	( my $t2 = "@tuning" ) =~ s/\d//g;
	if ( $t1 ne $t2 ) {
	    warn("Tuning changed, chords flushed\n")
	      if $options->{verbose} > 1;
	    @chordnames = ();
	    %config_chords = ();
	}
    }
    else {
	@chordnames = ();
	%config_chords = ();
    }
    @tuning = @$t;		# need more checks
    assert_tuning();
    return;

}

# API: Get tuning.
# Used by: String substitution.
sub get_tuning {
    @{[@tuning]};
}

# API: Set target parser.
# Used by: ChordPro.
sub set_parser {
    my ( $p ) = @_;

    $p = App::Music::ChordPro::Chords::Parser->get_parser($p)
      unless ref($p) && $p->isa('App::Music::ChordPro::Chords::Parser');
    $parser = $p;
    warn( "Parser: ", $parser->{system}, "\n" )
      if $options->{verbose} > 1;

    return;
}

# Parser stack.

my @parsers;

# API: Reset current parser.
# Used by: Config.
sub reset_parser {
    undef $parser;
    @parsers = ();
}

sub get_parser {
    $parser;
}

sub push_parser {
    my ( $p ) = @_;
    $p = App::Music::ChordPro::Chords::Parser->get_parser($p)
      unless ref($p) && $p->isa('App::Music::ChordPro::Chords::Parser');
    push( @parsers, $p );
    $parser = $p;
}

sub pop_parser {
    Carp::croak("Parser stack underflow") unless @parsers;
    $parser = pop(@parsers);
}

################ Section Config & User Chords ################

sub _known_chord {
    my ( $name ) = @_;
    my $info;
    if ( ref($name) =~ /^App::Music::ChordPro::Chord::/ ) {
	$info = $name;
	$name = $info->name;
    }
    my $ret = $song_chords{$name} // $config_chords{$name};
    return $ret if $ret || !$info;

    # Retry agnostic. Not all can do that.
    $name = eval { $info->agnostic };
    return unless $name;
    $ret = $song_chords{$name} // $config_chords{$name};
    if ( $ret ) {
	$ret = $info->new($ret);
	for ( qw( name display
		  root root_canon
		  bass bass_canon
		  system parser ) ) {
	    next unless defined $info->{$_};
	    $ret->{$_} = $info->{$_};
	}
    }
    $ret;
}

sub _check_chord {
    my ( $ii ) = @_;
    my ( $name, $base, $frets, $fingers, $keys )
      = @$ii{qw(name base frets fingers keys)};
    if ( $frets && @$frets != strings() ) {
	return scalar(@$frets) . " strings";
    }
    if ( $fingers && @$fingers && @$fingers != strings() ) {
	return scalar(@$fingers) . " strings for fingers";
    }
    unless ( $base > 0 && $base < 24 ) {
	return "base-fret $base out of range";
    }
    if ( $keys && @$keys ) {
	for ( @$keys ) {
	    return "invalid key \"$_\"" unless /^\d+$/ && $_ < 24;
	}
    }
    return;
}

# API: Add a config defined chord.
# Used by: Config.
sub add_config_chord {
    my ( $def ) = @_;
    my $res;
    my $name;

    # Handle alternatives.
    my @names;
    if ( $def->{name} =~ /\|/ ) {
	$def->{name} = [ split( /\|/, $def->{name} ) ];
    }
    if ( UNIVERSAL::isa( $def->{name}, 'ARRAY' ) ) {
	$name = shift( @{ $def->{name} } );
	push( @names, @{ $def->{name} } );
    }
    else {
	$name = $def->{name};
    }

    # For derived chords.
    if ( $def->{copy} ) {
	$res = $config_chords{$def->{copy}};
	return "Cannot copy $def->{copy}"
	  unless $res;
	$def = bless { %$res, %$def } => ref($res);
    }
    delete $def->{name};
    $def->{base} ||= 1;

    my ( $base, $frets, $fingers, $keys ) =
      ( $def->{base}, $def->{frets}, $def->{fingers}, $def->{keys} );
    $res = _check_chord($def);
    return $res if $res;

    for $name ( $name, @names ) {
	my $info = parse_chord($name) //
	  App::Music::ChordPro::Chord::Common->new({ name => $name });

	if ( $info->is_chord && $def->{copy} && $def->is_chord ) {
	    for ( qw( root bass ext qual ) ) {
		delete $def->{$_};
		delete $def->{$_."_mod"};
		delete $def->{$_."_canon"};
	    }
	    for ( qw( ext qual ) ) {
		delete $def->{$_};
		delete $def->{$_."_canon"};
	    }
	}
	Carp::confess(::dump($parser)) unless $parser->{target};
	$config_chords{$name} = bless
	  { origin  => "config",
	    system  => $parser->{system},
	    %$info,
	    %$def,
	    base    => $base,
	    baselabeloffset => $def->{baselabeloffset}||0,
	    frets   => [ $frets && @$frets ? @$frets : () ],
	    fingers => [ $fingers && @$fingers ? @$fingers : () ],
	    keys    => [ $keys && @$keys ? @$keys : () ]
	  } => $parser->{target};
	push( @chordnames, $name );
	next if $def->{copy};

	# Also store the chord info under a neutral name so it can be
	# found when other note name systems are used.
	my $i;
	if ( $info->is_chord ) {
	    $i = $info->agnostic;
	}
	else {
	    # Retry with default parser.
	    $i = App::Music::ChordPro::Chords::Parser->default->parse($name);
	    if ( $i && $i->is_chord ) {
		$info->{root_ord} = $i->{root_ord};
		$config_chords{$name}->{$_} = $i->{$_}
		  for qw( root_ord ext_canon qual_canon );
		$i = $i->agnostic;
	    }
	}
	if ( $info->is_chord ) {
	    $config_chords{$i} = $config_chords{$name};
	    $config_chords{$i}->{origin} = "config";
	}
    }
    return;
}

# API: Add a user defined chord.
# Used by: Songbook, Output::PDF.
sub add_song_chord {
    my ( $ii ) = @_;

    if ( $ii->{copy} ) {
	my $res = $song_chords{$ii->{copy}} // $config_chords{$ii->{copy}};
	return "Cannot copy $ii->{copy}"
	  unless $res;
	$ii = { %$res, %$ii };
    }
    my $res = _check_chord($ii);
    return $res if $res;
    my ( $name, $display, $base, $frets, $fingers, $keys )
      = @$ii{qw(name display base frets fingers keys)};
    my $info = parse_chord($name) // { name => $name };

    $song_chords{$name} = bless
      { origin  => "user",
	system  => $parser->{system},
	parser  => $parser,
	%$info,
	base    => $base,
	$display ? ( display => $display ) : (),
	frets   => [ $frets && @$frets ? @$frets : () ],
	fingers => [ $fingers && @$fingers ? @$fingers : () ],
	keys    => [ $keys && @$keys ? @$keys : () ],
      } => $parser->{target};
    return;
}

# API: Add an unknown chord.
# Used by: Songbook.
sub add_unknown_chord {
    my ( $name ) = @_;
    $song_chords{$name} = bless
      { origin  => "user",
	name    => $name,
	base    => 0,
	frets   => [],
	fingers => [],
        keys    => []
      } => $parser->{target};
}

# API: Reset user defined songs. Should be done for each new song.
# Used by: Songbook, Output::PDF.
sub reset_song_chords {
    %song_chords = ();
}

# API: Return some chord statistics.
sub chord_stats {
    my $res = sprintf( "%d config chords", scalar(keys(%config_chords)) );
    $res .= sprintf( ", %d song chords", scalar(keys(%song_chords)) )
      if %song_chords;
    return $res;
}

################ Section Chords Parser ################

sub parse_chord {
    my ( $chord ) = @_;
    my $res;

    unless ( $parser ) {
	$parser //= App::Music::ChordPro::Chords::Parser->get_parser;
	# warn("XXX ", $parser->{system}, " ", $parser->{n_pat}, "\n");
    }
    $res = $parser->parse($chord);
    return $res;
}

################ Section Keyboard keys ################

my %keys =
  ( ""       => [ 0, 4, 7 ],	             # major
    "-"      => [ 0, 3, 7 ],	             # minor
    "7"      => [ 0, 4, 7, 10 ],             # dominant 7th
    "-7"     => [ 0, 3, 7, 10 ],             # minor seventh
    "maj7"   => [ 0, 4, 7, 11 ],             # major 7th
	"-maj7"  => [ 0, 3, 7, 11 ],             # minor major 7th
	"6"      => [ 0, 4, 7, 9 ],              # 6th
	"-6"     => [ 0, 3, 7, 9 ],              # minor 6th
	"6/9"    => [ 0, 4, 7, 9, 14],           # 6/9
	"5"      => [ 0, 7 ],                    # 6th
	"9"      => [ 0, 4, 7, 10, 14 ],         # 9th
	"-9"     => [ 0, 3, 7, 10, 14 ],         # minor 9th
	"maj9"   => [ 0, 4, 7, 11, 14 ],         # major 9th
	"11"     => [ 0, 4, 7, 10, 14, 17 ],     # 11th
	"-11"    => [ 0, 3, 7, 10, 14, 17 ],     # minor 11th
	"13"     => [ 0, 4, 7, 10, 14, 17, 21 ], # 13th
	"-13"    => [ 0, 3, 7, 10, 14, 17, 21 ], # minor 13th
	"maj13"  => [ 0, 4, 7, 11, 14, 21 ],     # major 13th
	"add9"   => [ 0, 4, 7, 14 ],             # add 9
	"add2"   => [ 0, 2, 4, 7 ],              # add 2
	"7-5"    => [ 0, 4, 6, 10 ],             # 7 flat 5 altered chord
	"7+5"    => [ 0, 4, 8, 10 ],             # 7 sharp 5 altered chord
	"sus4"   => [ 0, 5, 7 ],                 # sus 4
	"sus2"   => [ 0, 2, 7 ],                 # sus 2
    "0"      => [ 0, 3, 6 ],	             # diminished
	"07"     => [ 0, 3, 6, 9 ],              # diminished 7
	"-7b5"   => [ 0, 3, 6, 10 ],             # minor 7 flat 5
    "+"      => [ 0, 4, 8 ],	             # augmented
	"+7"     => [ 0, 4, 8, 10 ],             # augmented 7
    "h"      => [ 0, 3, 6, 10 ],             # half-diminished seventh
  );

sub _get_keys {
    my ( $info ) = @_;
#    ::dump( { %$info, parser => ref($info->{parser}) });
    # Has keys defined.
    return $info->{keys} if $info->{keys} && @{$info->{keys}};

    # Known chords.
    return $keys{$info->{qual_canon}.$info->{ext_canon}}
      if defined $info->{qual_canon}
      && defined $info->{ext_canon}
      && defined $keys{$info->{qual_canon}.$info->{ext_canon}};

    # Try to derive from guitar chords.
    return [] unless $info->{frets} && @{$info->{frets}};
    my @tuning = ( 4, 9, 2, 7, 11, 4 );
    my %keys;
    my $i = -1;
    my $base = $info->{base} - 1;
    $base = 0 if $base < 0;
    for ( @{ $info->{frets} } ) {
	$i++;
	next if $_ < 0;
	my $c = $tuning[$i] + $_ + $base;
	$c += 12 if $c < $info->{root_ord};
	$c -= $info->{root_ord};
	$keys{ $c % 12 }++;
    }
    return [ keys %keys ];
}

################ Section Transposition ################

# API: Transpose a chord.
# Used by: Songbook.
sub transpose {
    my ( $c, $xpose, $xcode ) = @_;
    return $c unless $xpose || $xcode;
    return $c if $c =~ /^ .+/;
    my $info = parse_chord($c);
    unless ( $info ) {
	assert_tuning();
	for ( \%song_chords, \%config_chords ) {
	    # Not sure what this is for...
	    # Anyway, it causes unknown but {defined} chords to silently
	    # bypass the trans* warnings.
	    # return if exists($_->{$c});
	}
	$xpose
	  ? warn("Cannot transpose $c\n")
	  : warn("Cannot transcode $c\n");
	return;
    }

    my $res = $info->transcode($xcode)->transpose($xpose)->show;

#    Carp::cluck("__XPOSE = ", $xpose, " __XCODE = $xcode, chord $c => $res\n");

    return $res;
}

1;
