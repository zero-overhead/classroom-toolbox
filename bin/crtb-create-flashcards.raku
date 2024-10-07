#!/usr/bin/env raku
use v6.d;
use App::Classroom::Toolbox;
use JSON::Fast;

#| Creates Obsidian Flash Cards
sub MAIN(IO::Path(Str) :cf(:$class-file) where *.f = %*ENV<CRTB_CLASS_FILE>, #= file containing students information; --class-file=classes/demo-class-small or 'export CRTB_CLASS_FILE=classes/demo-class-small'
    ) {
    my %class = from-json $class-file.extension('json').slurp;
    my $flash-card-filename = $class-file.dirname.IO.add($class-file.basename ~ "-flashcards").extension('md');
    my @flashcard = "#Flashcards-" ~ $class-file.basename,;
    for %class.keys.sort -> $email {
        my $data = %class{$email};
        my $entry = "{$data<first-name>} {$data<sure-name>} ({$data<sex>})\n??\n![[{$email.lc}.jpg|180]]";
        @flashcard.push: $entry
    }
    say "writing: "  ~ %class.keys.elems ~  " entries to " ~ $flash-card-filename;
    spurt $flash-card-filename,  @flashcard.join("\n\n")
}