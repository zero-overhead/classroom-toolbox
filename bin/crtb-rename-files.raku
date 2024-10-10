#!/usr/bin/env raku
use v6.d;

sub MAIN (IO::Path(Str) :p(:$pictures-folder)                                                                         #= show how students see it, otherwise teacher view is selected
    ) {

    my @files = $pictures-folder.dir;

    # create captions and rename pictures
    for @files.grep( /\.jpg$$/ ) -> $picture {
        my $new-base = $picture.basename.lc;
        my $new-name = $picture.dirname.IO.add($new-base);
        my $new-caption-name = $picture.dirname.IO.add($new-base ~ '.txt');
        my $caption = $new-base ~~ /\w+/;
        spurt $new-caption-name, $caption.split('.').map: *.tc;
        $picture.rename($new-name)
    }
}