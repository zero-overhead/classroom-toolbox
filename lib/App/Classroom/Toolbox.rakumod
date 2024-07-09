unit class App::Classroom::Toolbox:ver<0.0.1>:auth<github:rcmlz>:api<1>;

use Text::Table::Simple;
use Terminal::ANSIColor;
use JSON::Fast;
use P5localtime;

constant pictographs = "\c[Bell with Cancellation Stroke]",
                       "\c[Penguin]",
                       "\c[BELL]",
                       "\c[Water Buffalo]",
                       "\c[Ox]",
                       "\c[Mouse]",
                       "\c[Rat]",
                       "\c[Confetti Ball]",
                       "\c[Clinking Beer Mugs]",
                       "\c[Doughnut]",
                       "\c[Burrito]",
                       "\c[Sun with Face]",
                       "\c[Full Moon with Face]",
                       "\c[Closed Umbrella]",
                       "\c[Taco]",
                       "\c[Hot Dog]",
                       "\c[Cloud with Tornado]",
                       "\c[Thermometer]",
                       "\c[Cyclone]",
                       "\c[Octopus]",
                       "\c[Elephant]",
                       "\c[Boar]",
                       "\c[Pig]",
                       "\c[Dog]",
                       "\c[Chicken]",
                       "\c[Rooster]",
                       "\c[Monkey]",
                       "\c[Sheep]",
                       "\c[Goat]",
                       "\c[Ram]",
                       "\c[Horse]",
                       "\c[Snake]",
                       "\c[Snail]",
                       "\c[Whale]",
                       "\c[Crocodile]",
                       "\c[Dragon]",
                       "\c[Cat]",
                       "\c[Rabbit]",
                       "\c[Leopard]",
                       "\c[Tiger]",
                       "\c[Cat Face]",
                       "\c[Rabbit Face]",
                       "\c[Tiger Face]",
                       "\c[Cow Face]",
                       "\c[Mouse Face]",
                       "\c[Dolphin]",
                       "\c[Bactrian Camel]",
                       "\c[Dromedary Camel]",
                       "\c[Poodle]",
                       "\c[Koala]",
                       "\c[Bird]",
                       "\c[Front-Facing Baby Chick]",
                       "\c[Baby Chick]",
                       "\c[Hatching Chick]",
                       "\c[Turtle]",
                       "\c[Blowfish]",
                       "\c[Tropical Fish]",
                       "\c[Fish]",
                       "\c[Lady Beetle]",
                       "\c[Honeybee]",
                       "\c[Ant]",
                       "\c[Bug]",
                       "\c[Spiral Shell]",
                       "\c[Dragon Face]",
                       "\c[Spouting Whale]",
                       "\c[Horse Face]",
                       "\c[Monkey Face]",
                       "\c[Dog Face]",
                       "\c[Pig Face]",
                       "\c[Frog Face]",
                       "\c[Hamster Face]",
                       "\c[Wolf Face]",
                       "\c[Bear Face]",
                       "\c[Panda Face]",
                       "\c[Pig Nose]",
                       "\c[Paw Prints]",
                       "\c[Chipmunk]",
                       "\c[Eyes]",
                       "\c[Eye]",
                       "\c[Cow]";

constant %text-table-simple-options =
rows => {
    column_separator => '',
    bottom_left_corner_marker => '',
    bottom_right_corner_marker => '',
    bottom_corner_marker => '',
    bottom_border => '',
},
headers => {
    top_border => '',
    column_separator => '',
    top_corner_marker => '',
    top_left_corner_marker => '',
    top_right_corner_marker => '',
    bottom_left_corner_marker => '',
    bottom_right_corner_marker => '',
    bottom_corner_marker => '',
    bottom_border => '',
};

sub format-elapsed-time($elapsed) {
    my $hours = $elapsed.Int div 3600;
    my $minutes = ($elapsed.Int mod 3600) div 60;
    my $seconds = $elapsed.Int mod 60;
    if $minutes < 1 {
        return $hours.fmt("%02d") ~ ':' ~ $minutes.fmt("%02d") ~ ':' ~ $seconds.fmt("%02d");
    } else {
        return $hours.fmt("%02d") ~ ':' ~ $minutes.fmt("%02d");
    }
}
sub timer(\Terminal, $minutes=1) is export {
    my $start = now;
    my $end = $start + 60 * $minutes + 1;

    my ($sec,$minute,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($end);

    $minute = "0$minute" if $minute < 10;
    $hour = "0$hour" if $hour < 10;

    my @columns = ^Terminal.columns;
    my @rows = ^Terminal.rows;

    my $x = @columns.elems / 2 - 5;
    my $y = @rows.elems / 2 - 1;

    Terminal.print-string( @columns.elems - 6, @rows.elems - 1, join ":", $hour, $minute);

    my $time-left = $end - now;

    while $time-left > 0 {
        Terminal.print-string( $x, $y, format-elapsed-time($time-left));

        # print progress dots
        my $printable = ((@columns.elems - 9) * (now - $start)/($end - $start)).Int;
        for ^$printable -> $col {
            Terminal.print-string( 1 + $col, @rows.elems - 1, '.');
        }

        $time-left = $end - now;
        sleep 1 if $time-left < 70;
        sleep 10 if $time-left >= 70;
    }

    # itgnore last row/column
    @columns.pop;
    @rows.pop;
    my $symbol = pictographs.pick;
    for (@columns X @rows).pick(*) -> ($x, $y) {
        next if $x %% 2;
        Terminal.print-string( $x, $y, $symbol);
        sleep 0.001;
    }
}
sub get-class(IO $class-file) {
    $class-file.lines.grep(/^^\w/);
}

sub extract-emails(@class) {
    @class.map: { .split(',').map(*.trim)[3] }
}

sub extract-names(@class) {
    @class.map: { .split(',').map(*.trim)[2, 1] }
}

sub pick-group-from-class-file(IO $class-file, UInt :$group-size, IO :$pictures-folder?) is export {
    my @class = get-class($class-file);
    my @group = @class.pick($group-size);
    my @names = extract-names(@group);
    print "\n";
    .join(" ").say for @names;

    with $pictures-folder {
        my $extension = '.jpg';
        my @emails = extract-emails(@group);
        my @fotos = gather {
            for @emails {
                my $foto = $pictures-folder.add("$_$extension");
                take $foto if $foto.IO.f
            }
        }
        if @fotos.elems > 0 {
            my $tool = 'display';
            # Linux only, provided by imagemagick
            $tool = 'open' if $*DISTRO.name.contains("macos");
            my $cmd = "timeout --kill-after=1 3 $tool " ~ @fotos.join(' ');
            my $p = shell $cmd;
            $p = Nil
        }
    }
}

sub init-folders is export {

    note "\nWorkdir:\n" ~ $*CWD;
    note "\nStandard folders:";
    for sort <pictures classes rooms placements grades groups> {
        note $_;
        $*CWD.add($_).mkdir;
    }
    note "\nDemo files:";
    for flat <classes/demo-class-large classes/demo-class-small>,
            <rooms/demo-room-1 rooms/demo-room-2 rooms/demo-room-3>,
            <groups/demo-grouping>,
            <placements/demo-placement>,
            <pictures/Leon.Braun@school.de.jpg pictures/Lukas.Schäfer@school.de.jpg pictures/Maxi.Schneider@school.de.jpg pictures/Niklas.Hartmann@school.de.jpg> {
        note $_;
        %?RESOURCES{$_}.copy($*CWD.add($_));
    }
}

sub create-header(@room  --> Str) {
    my $width = max @room.map: *.join.chars;
    my $header =
            ~"\n"
                    ~ "-" x $width
                    ~ "\n"
                    ~ "Chalkboard".indent(($width div 2) - 5)
                    ~ "\n"
            ~ "-" x $width;
    return $header
}

sub create-footer(@room --> Str) {
    my $width = max @room.map: *.join.chars;
    my $footer = "-" x $width;
    return $footer
}

sub create-student-view(@room) is export {
    my @placement = lol2table(@room, |%text-table-simple-options);
    join "\n", create-header(@placement), @placement, create-footer(@placement)
}

sub create-teacher-view(@room) is export {
    my @room-teacher-view = @room.reverse.map: { Array.new($_.reverse) };
    my @placement = lol2table(@room-teacher-view, |%text-table-simple-options);
    join "\n", create-footer(@placement), @placement, create-header(@placement)
}

sub create-placement(IO $class-file, IO $room-file, IO $placement-dir, UInt $max-name-width) is export {
    my @not-placed-students = extract-names(get-class($class-file)).pick(*);
    my @room = $room-file.lines.map: { Array.new: $_.comb };

    # pre-process student names
    @not-placed-students = @not-placed-students.map({ .substr(0, $max-name-width) });

    # create placement
    for ^@room.elems -> $row_id {
        for ^@room[$row_id].elems -> $seat {
            my $marker = @room[$row_id][$seat];
            if $marker eq "1" and @not-placed-students.elems {
                @room[$row_id][$seat] = @not-placed-students.pop
            } elsif $marker eq "1" and not @not-placed-students.elems {
                @room[$row_id][$seat] = "X"
            }
        }
    }

    my $class = $class-file.basename;
    my $room = $room-file.basename;
    my $date = Date.today;
    my $placement-file-name = $placement-dir.add(join '_', $date, $class, $room);

    spurt $placement-file-name, to-json @room;

    .say for create-student-view(@room);

    if @not-placed-students {
        my $placement-file-name-missing = join '_', $date, $class, $room, "not-placed";
        spurt $placement-dir.add($placement-file-name-missing), to-json @not-placed-students;
        note "\nNoch nicht platziert: " ~ @not-placed-students.join(", ") ~ "\n"
    }

    print "\n";
    say "export CRTB_PLACEMENT=$placement-file-name"
}

sub create-groups($class-file, $primary-size, $secondary-size) is export {
    my @students = extract-names(get-class($class-file)).pick(*);
    my $n = @students.elems;

    gather {
        ($secondary-size, $primary-size) Z=> ((0 .. ($n div $secondary-size)) X (0 .. ($n div $primary-size)) andthen
                .first({ (sum $_ >>*<< ($secondary-size,
                                        $primary-size)) == $n })) || note "\nImpossible to split $n students into groups of sizes $primary-size and $secondary-size !!\n" andthen
                .sort.map({
                    my UInt $gsize = .key;
                    my UInt $gcount = .value;
                    for ^$gcount { take @students.splice(0, $gsize) }
                });

    }
}

=begin pod

=head1 NAME

App:Classroom::Toolbox - Simple Classroom Management Toolbox.

=head1 DESCRIPTION

Classroom::Toolbox is a collection of simple scripts teachers need to manage a classroom.

=head1 Tools

=begin code :lang<bash>
crtb-tool-name --help
=end code

=begin code :lang<bash>
crtb-init-folders

crtb-create-placement
crtb-display-placement

crtb-create-groups
crtb-display-groups

crtb-pick-group-from-placement-file
crtb-pick-group-from-class-file

crtb-timer
=end code

=head1 CONFIGURATION

Set defaults to be used by tools - if you do not like to use the corresponding command line parameters.

=begin code :lang<bash>
export CRTB_CLASS=classes/demo-class-large
export CRTB_ROOM=rooms/demo-room-1
=end code

After you created a placement, grouping or grading you might want to set
=begin code :lang<bash>
export CRTB_PLACEMENT=placements/demo-placement
export CRTB_GROUP=groups/demo-grouping
export CRTB_GRADE=grades/demo-grading
=end code

This usually won't change much - perhaps use direnv to set these automatically
=begin code :lang<bash>
export CRTB_PICTURE_FOLDER=pictures
export CRTB_PLACEMENTS_FOLDER=placements
export CRTB_GRADES_FOLDER=grades
export CRTB_GROUP_FOLDER=groups
=end code

=defn classes/
--class-file= or CRTB_CLASS=

=defn rooms/ 
--room-file= or CRTB_ROOM=

=defn pictures/ 
--picture-folder= or CRTB_PICTURE_FOLDER=

=defn placements/
--placement-file= or export CRTB_PLACENMENT=placements/demo-placement

=defn grades
t.b.d

=head1 SETUP

=begin code :lang<bash>

git clone https://github.com/zero-overhead/classroom-toolbox
cd classroom-toolbox
zef install .

=end code

=defn imagemagick
required for showing pictures on Linux, install

=begin code :lang<bash>
brew install imagemagick
=end code

or e.g.

=begin code :lang<bash>
nix-shell -p imagemagick
=end code

=head1 AUTHOR

rcmlz <19784049+rcmlz@users.noreply.github.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 rcmlz

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
