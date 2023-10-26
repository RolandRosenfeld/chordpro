#! perl

use strict;
use warnings;
use utf8;

# Implementation of ChordPro::Wx::PreferencesDialog_wxg details.

package ChordPro::Wx::PreferencesDialog;

# ChordPro::Wx::PreferencesDialog_wxg is generated by wxGlade and contains
# all UI associated code.

use base qw( ChordPro::Wx::PreferencesDialog_wxg );

use Wx qw[:everything];
use Wx::Locale gettext => '_T';
use App::Packager;
use ChordPro::Utils qw(is_macos);

# BUilt-in descriptions for some notation systems.
my $notdesc =
  { "common"	   => "C, D, E, F, G, A, B",
    "dutch"	   => "C, D, E, F, G, A, B",
    "german"	   => "C, ... A, Ais/B, H",
    "latin"	   => "Do, Re, Mi, Fa, Sol, ...",
    "scandinavian" => "C, ... A, A#/Bb, H",
    "solfege"	   => "Do, Re, Mi, Fa, So, ...",
    "solfège"	   => "Do, Re, Mi, Fa, So, ...",
    "nashville"	   => "1, 2, 3, ...",
    "roman"	   => "I, II, III, ...",
  };

my $is_macos_crippled = is_macos();

sub get_configfile {
    my ( $self ) = @_;
    # warn("CF: ", $self->GetParent->{prefs_configfile} || "");
    $self->GetParent->{prefs_configfile} || ""
}

# As of wxGlade 1.0 __set_properties and __do_layout are gone.
sub new {
    my $self = shift->SUPER::new(@_);
    $self->fetch_prefs();
    $self;
}

sub _enablecustom {
    my ( $self ) = @_;
    my $n = $self->{cb_configfile}->IsChecked;
    for ( $self->{t_configfiledialog}, $self->{b_configfiledialog} ) {
	$_->Enable($n);
    }

    $n = $self->{cb_customlib}->IsChecked;
    for ( $self->{t_customlibdialog}, $self->{b_customlibdialog} ) {
	$_->Enable($n);
    }

    $n = $self->{cb_tmplfile}->IsChecked;
    for ( $self->{t_tmplfiledialog}, $self->{b_tmplfiledialog} ) {
	$_->Enable($n);
    }
}

sub fetch_prefs {
    my ( $self ) = @_;

    # Fetch preferences from parent.

    my $parent = $self->GetParent;

    # Skip default (system, user, song) configs.
    $self->{cb_skipstdcfg}->SetValue($parent->{prefs_skipstdcfg});

    # Presets.
    $self->{cb_presets}->SetValue($parent->{prefs_enable_presets});
    $self->{ch_presets}->Enable($parent->{prefs_enable_presets});
    my $ctl = $self->{ch_presets};
    $ctl->Clear;
    for ( @{ $parent->stylelist } ) {
	my $t = ucfirst(lc($_));
	$t =~ s/_/ /g;
	$t =~ s/ (.)/" ".uc($1)/eg;
	$ctl->Append($t);
    }

    my $p = $parent->{prefs_cfgpreset};
    foreach ( @$p ) {
	if ( $_ eq "custom" ) {
	    $self->{cb_configfile}->SetValue(1);
	    next;
	}
	my $t = ucfirst(lc($_));
	$t =~ s/_/ /g;
	$t =~ s/ (.)/" ".uc($1)/eg;
	my $n = $ctl->FindString($t);
	unless ( $n == wxNOT_FOUND ) {
	    $ctl->Check( $n, 1 );
	}
    }

    # Custom config file.
    $self->{cb_configfile}->SetValue($parent->{prefs_enable_configfile});
    $self->{t_configfiledialog}->SetValue($parent->{prefs_configfile})
      if $parent->{prefs_configfile};

    # Custom library.
    $self->{cb_customlib}->SetValue($parent->{prefs_enable_customlib});
    $self->{t_customlibdialog}->SetValue($parent->{prefs_customlib})
      if $parent->{prefs_customlib};

    # New song template.
    $self->{cb_tmplfile}->SetValue($parent->{prefs_enable_tmplfile});
    $self->{t_tmplfiledialog}->SetValue($parent->{prefs_tmplfile})
      if $parent->{prefs_tmplfile};

    # Editor.
    $ctl = $self->{ch_editfont};
    $ctl->SetSelection( $parent->{prefs_editfont} );
    $ctl = $self->{sp_editfont};
    $ctl->SetValue( $parent->{prefs_editsize} );

    # Notation.
    $ctl = $self->{ch_notation};
    $ctl->Clear;
    my $n = 0;
    my $check = 0;
    for ( @{ $parent->notationlist } ) {
	my $s = ucfirst($_);
	$check = $n if $_ eq lc $parent->{prefs_notation};
	$s .= " (" . $notdesc->{lc($s)} .")" if $notdesc->{lc($s)};
	$ctl->Append($s);
	$ctl->SetClientData( $n, $_);
	$n++;
    }
    $ctl->SetSelection($check);

    # Transpose.

    # Transcode.
    $ctl = $self->{ch_transcode};
    $ctl->Clear;
    $ctl->Append("-----");
    $n = 1;
    for ( @{ $parent->notationlist } ) {
	my $s = ucfirst($_);
	$check = $n if $_ eq lc $parent->{prefs_xcode};
	$s .= " (" . $notdesc->{lc($s)} .")" if $notdesc->{lc($s)};
	$ctl->Append($s);
	$ctl->SetClientData( $n, $_);
	$n++;
    }
    $ctl->SetSelection($check);

    # PDF Viewer.
    $self->{t_pdfviewer}->SetValue($parent->{prefs_pdfviewer})
      if $parent->{prefs_pdfviewer};

    $self->_enablecustom;

    if ( $is_macos_crippled ) {
	# Cannot use chooser, hide button and change tooltip.
	for ( qw( configfile customlib tmplfile ) ) {
	    $self->{"sz_$_"}->Hide($self->{"b_${_}dialog"});
	    $self->{"sz_$_"}->Layout;
	    my $t = $self->{"t_${_}dialog"}->GetToolTip->GetTip;
	    $t =~ s/ by pressing .* button//;
	    $self->{"t_${_}dialog"}->SetToolTipString($t);
	}
    }
}

#               C      D      E  F      G      A        B C
my @xpmap = qw( 0 1  1 2 3  3 4  5 6  6 7 8  8 9 10 10 11 12 );
my @sfmap = qw( 0 7 -5 2 9 -3 4 -1 6 -6 1 8 -4 3 10 -2  5 0  );

sub store_prefs {
    my ( $self ) = @_;

    # Transfer all preferences to the parent.
    my $parent = $self->GetParent;

    # Skip default (system, user, song) configs.
    $parent->{prefs_skipstdcfg}  = $self->{cb_skipstdcfg}->IsChecked;

    # Presets.
    $parent->{prefs_enable_presets} = $self->{cb_presets}->IsChecked;
    my $ctl = $self->{ch_presets};
    my $cnt = $ctl->GetCount;
    my @p;
    my $styles = $parent->stylelist;
    for ( my $n = 0; $n < $cnt; $n++ ) {
	next unless $ctl->IsChecked($n);
	push( @p, $styles->[$n] );
	if ( $n == $cnt - 1 ) {
	    my $c = $self->{t_configfiledialog}->GetValue;
	    if ( $is_macos_crippled && ! -r $c ) {
		my $md = Wx::MessageDialog->new
		  ( $self,
		    "Custom config file $c can not be read.\n".
		    "Please enter the name of an existing config file.",
		    "Config file can not be read",
		    0 | wxOK | wxICON_QUESTION );
		my $ret = $md->ShowModal;
		$md->Destroy;
		return;
	    }
	    $parent->{_cfgpresetfile} =
	      $parent->{prefs_configfile} = $c;
	}
    }
    $parent->{prefs_cfgpreset} = \@p;

    # Custom config file.
    $parent->{prefs_enable_configfile} = $self->{cb_configfile}->IsChecked;
    $parent->{prefs_configfile}        = $self->{t_configfiledialog}->GetValue;

    # Custom library.
    $parent->{prefs_enable_customlib} = $self->{cb_customlib}->IsChecked;
    $parent->{prefs_customlib}        = $ENV{CHORDPRO_LIB} // $self->{l_customlibdialog}->GetValue;

    # New song template.
    $parent->{prefs_enable_tmplfile} = $self->{cb_tmplfile}->IsChecked;
    $parent->{prefs_tmplfile}        = $self->{t_tmplfiledialog}->GetValue;

    # Editor.
    $parent->{prefs_editfont}	   = $self->{ch_editfont}->GetSelection;
    $parent->{prefs_editsize}	   = $self->{sp_editfont}->GetValue;

    # Notation.
    my $n = $self->{ch_notation}->GetSelection;
    if ( $n > 0 ) {
	$parent->{prefs_notation} =
	  $self->{ch_notation}->GetClientData($n);
    }
    else {
       	$parent->{prefs_notation} = "";
    }

    # Transpose.
    $parent->{prefs_xpose_from} = $xpmap[$self->{ch_xpose_from}->GetSelection];
    $parent->{prefs_xpose_to  } = $xpmap[$self->{ch_xpose_to  }->GetSelection];
    $parent->{prefs_xpose_acc}  = $self->{ch_acc}->GetSelection;
    $n = $parent->{prefs_xpose_to} - $parent->{prefs_xpose_from};
    $n += 12 if $n < 0;
    $n += 12 if $parent->{prefs_xpose_acc} == 1; # sharps
    $n -= 12 if $parent->{prefs_xpose_acc} == 2; # flats
    $parent->{prefs_xpose} = $n;

    # Transcode.
    $n = $self->{ch_transcode}->GetSelection;
    if ( $n > 0 ) {
	$parent->{prefs_xcode} =
	  $self->{ch_transcode}->GetClientData($n);
    }
    else {
       	$parent->{prefs_xcode} = "";
    }

    # PDF Viewer.
    $parent->{prefs_pdfviewer} = $self->{t_pdfviewer}->GetValue;
}

################ Event handlers ################

# Event handlers override the subs generated by wxGlade in the _wxg class.

sub OnConfigFile {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_configfile}->IsChecked;
    for ( $self->{t_configfiledialog}, $self->{b_configfiledialog} ) {
	$_->Enable($n);
    }
    $event->Skip;
}

sub OnConfigFileDialog {
    my ( $self, $event ) = @_;
    my $fd = Wx::FileDialog->new
      ($self, _T("Choose config file"),
       "", $self->GetParent->{prefs_configfile} || "",
       "Config files (*.cfg,*.json)|*.cfg;*.json|All files|*.*",
       0|wxFD_OPEN,
       wxDefaultPosition);
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $fd->GetPath;
	if ( -f $file ) {
	    $self->{t_configfiledialog}->SetValue($file);
	}
	else {
	    my $md = Wx::MessageDialog->new
	      ( $self,
		"Create new config $file?",
		"Creating a config file",
		wxYES_NO | wxICON_INFORMATION );
	    my $ret = $md->ShowModal;
	    $md->Destroy;
	    if ( $ret == wxID_YES ) {
		my $fd;
		if ( open( $fd, ">:utf8", $file )
		     and print $fd ChordPro::Config::default_config()
		     and close($fd) ) {
		    $self->{t_configfiledialog}->SetValue($file);
		}
		else {
		    my $md = Wx::MessageDialog->new
		      ( $self,
			"Error creating $file: $!",
			"File open error",
			wxOK | wxICON_ERROR );
		    $md->ShowModal;
		    $md->Destroy;
		}
	    }
	}
    }
    $fd->Destroy;
}

sub OnCustomLib {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_customlib}->IsChecked;
    for ( $self->{t_customlibdialog}, $self->{b_customlibdialog} ) {
	$_->Enable($n);
    }
}

sub OnCustomLibDialog {
    my ( $self, $event ) = @_;
    my $fd = Wx::DirDialog->new
      ($self, _T("Choose custom library"),
       $self->GetParent->{prefs_customlib} || "",
       0|wxDD_DIR_MUST_EXIST,
       wxDefaultPosition);
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $fd->GetPath;
	$self->{t_customlibdialog}->SetValue($file);
	$ENV{CHORDPRO_LIB} = $file;
    }
    $fd->Destroy;
}

sub OnTmplFile {
    my ( $self, $event ) = @_;
    my $n = $self->{cb_tmplfile}->IsChecked;
    for ( $self->{t_tmplfiledialog}, $self->{b_tmplfiledialog} ) {
	$_->Enable($n);
    }
}

sub OnTmplFileDialog {
    my ( $self, $event ) = @_;
    my $fd = Wx::FileDialog->new
      ($self, _T("Choose template for new songs"),
       "", $self->GetParent->{prefs_tmplfile} || "",
       "ChordPro files (*.cho,*.crd,*.chopro,*.chord,*.chordpro,*.pro)|*.cho;*.crd;*.chopro;*.chord;*.chordpro;*.pro|All files|*.*",
       0|wxFD_OPEN|wxFD_FILE_MUST_EXIST,
       wxDefaultPosition);
    my $ret = $fd->ShowModal;
    if ( $ret == wxID_OK ) {
	my $file = $fd->GetPath;
	$self->{t_tmplfiledialog}->SetValue($file);
    }
    $fd->Destroy;
}

sub OnAccept {
    my ( $self, $event ) = @_;
    $self->store_prefs();
    $event->Skip;
}

sub OnCancel {
    my ( $self, $event ) = @_;
    $event->Skip;
}

sub OnSkipStdCfg {
    my ( $self, $event ) = @_;
    $event->Skip;
}

sub OnPresets {
    my ( $self, $event ) = @_;
    $self->{ch_presets}->Enable( $self->{cb_presets}->GetValue );
    $event->Skip;
}

sub OnXposeFrom {
    my ( $self, $event ) = @_;
    $self->OnXposeTo($event);
}

sub OnXposeTo {
    my ( $self, $event ) = @_;
    my $sel = $self->{ch_xpose_to}->GetSelection;
    my $sf = $sfmap[$sel];
    if ( $sf == 0 ) {
	$sf = $sel - $self->{ch_xpose_from}->GetSelection;
    }
    if ( $sf < 0 ) {
	$self->{ch_acc}->SetSelection(2);
    }
    elsif ( $sf > 0 ) {
	$self->{ch_acc}->SetSelection(1);
    }
    else {
	$self->{ch_acc}->SetSelection(0);
    }
    $event->Skip;
}

sub OnChNotation {
    my ( $self, $event ) = @_;
    my $n = $self->{ch_notation}->GetSelection;
    $event->Skip;
}

sub OnChTranscode {
    my ( $self, $event ) = @_;
    my $n = $self->{ch_transcode}->GetSelection;
    $event->Skip;
}

sub OnChEditFont {
    my ($self, $event) = @_;
    my $p = $self->GetParent;
    my $n = $self->{ch_editfont}->GetSelection;
    my $ctl = $p->{t_source};
    my $font = $p->fonts->[$n]->{font};
    $font->SetPointSize($p->{prefs_editsize});
    $ctl->SetFont($font);
    $p->{prefs_editfont} = $n;
    $event->Skip;
}

sub OnSpEditFont {
    my ($self, $event) = @_;
    my $p = $self->GetParent;
    my $n = $self->{sp_editfont}->GetValue;
    my $ctl = $p->{t_source};
    my $font = $ctl->GetFont;
    $font->SetPointSize($n);
    $ctl->SetFont($font);
    $p->{prefs_editsize} = $n;
    $event->Skip;
}

1;
