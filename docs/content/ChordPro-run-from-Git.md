# Running from Git

If you want to keep track of the latest developments you can run
Chordpro directly from the Git repository.

It is easiest to first install the release version of ChordPro using
one of the techniques mentioned on the [[Installing
ChordPro|ChordPro-Installation]] page. This will make sure most of the
required dependencies are installed.

Unless git is already installed, install it from the package repository.

Then, on the command line:

    git clone https://github.com/ChordPro/chordpro

This will create a new directory `chordpro`.

    cd chordpro
    git checkout dev
	perl Makefile.PL
	
This will inform you about missing dependencies. If so, install the
missing dependencies the usual way (package repository, `cpan` tool...).
	
To verify the installation, run

	make all test
    perl script/chordpro --version

This should say something similar to

    This is ChordPro version 0.974_036

To run `chordpro` use

	perl script/chordpro 