#!/usr/bin/env raku
use v6.d;

sub MAIN (IO::Path(Str) :pf(:$pictures-folder)                                                                         #= show how students see it, otherwise teacher view is selected
    ) {

    my @files = $pictures-folder.dir;
    for @files -> $picture {
        my $new-base = $picture.basename.lc;
        my $new-name = $picture.dirname.IO.add($new-base);
        $picture.rename($new-name)
    }
}