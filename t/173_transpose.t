#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

use App::Music::ChordPro::Config;
use App::Music::ChordPro::Songbook;

our $config = App::Music::ChordPro::Config::configurator;
# Prevent a dummy {body} for chord grids.
$config->{diagrams}->{show} = 0;
my $s = App::Music::ChordPro::Songbook->new;

my $data = <<EOD;
{title: Transpositions}
{key: D}

{start_of_chorus}
Swing [D]low, sweet [G]chari[D]ot,
{end_of_chorus}

I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose +2}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose +2}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}

{transpose}
I [D]looked over Jordan, and [G]what did I [D]see,
{chorus}
EOD

eval { $s->parsefile( \$data, { transpose => -10 } ) } or diag("$@");

ok( scalar( @{ $s->{songs} } ) == 1, "One song" );
isa_ok( $s->{songs}->[0], 'App::Music::ChordPro::Song', "It's a song" );

my $song = {
  body => [
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'E',
        'A',
        'E',
      ],
      context => 'chorus',
      phrases => [
        'Swing ',
        'low, sweet ',
        'chari',
        'ot,',
      ],
      type => 'songline',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      chords => [
        '',
        'E',
        'A',
        'E',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'E',
            'A',
            'E',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
      ],
      context => '',
      transpose => 0,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      context => '',
      name => 'transpose',
      previous => 0,
      type => 'control',
      value => 2,
    },
    {
      chords => [
        '',
        'Gb',
        'B',
        'Gb',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'Gb',
            'B',
            'Gb',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
      ],
      context => '',
      transpose => 2,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      context => '',
      name => 'transpose',
      previous => 2,
      type => 'control',
      value => 4,
    },
    {
      chords => [
        '',
        'Ab',
        'Db',
        'Ab',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'Ab',
            'Db',
            'Ab',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
      ],
      context => '',
      transpose => 4,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      context => '',
      name => 'transpose',
      previous => 4,
      type => 'control',
      value => 2,
    },
    {
      chords => [
        '',
        'Gb',
        'B',
        'Gb',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'Gb',
            'B',
            'Gb',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
      ],
      context => '',
      transpose => 2,
      type => 'rechorus',
    },
    {
      context => '',
      type => 'empty',
    },
    {
      context => '',
      name => 'transpose',
      previous => 2,
      type => 'control',
      value => 0,
    },
    {
      chords => [
        '',
        'E',
        'A',
        'E',
      ],
      context => '',
      phrases => [
        'I ',
        'looked over Jordan, and ',
        'what did I ',
        'see,',
      ],
      type => 'songline',
    },
    {
      chorus => [
        {
          chords => [
            '',
            'E',
            'A',
            'E',
          ],
          context => 'chorus',
          phrases => [
            'Swing ',
            'low, sweet ',
            'chari',
            'ot,',
          ],
          type => 'songline',
        },
      ],
      context => '',
      transpose => 0,
      type => 'rechorus',
    },
  ],
  meta => {
    key => [
      'E',
    ],
    title => [
      'Transpositions',
    ],
  },
  settings => {},
  structure => 'linear',
  title => 'Transpositions',
};

is_deeply( { %{ $s->{songs}->[0] } }, $song, "Song contents" );