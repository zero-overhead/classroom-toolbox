unit class App::Classroom::Toolbox:ver<0.0.1>:auth<github:rcmlz>:api<1>;

use Text::Table::Simple;
use Terminal::ANSIColor;
use JSON::Fast;

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


sub get-class(IO $class-file) {
    $class-file.lines.grep(/^^\w/);
}

sub extract-emails(@class) {
    @class.map: { .split(',').map(*.trim)[3] }
}

sub extract-names(@class) {
    my @names = @class.map({ .split(',').map(*.trim)[2, 1] });
    my @surenames;
    my @first-names;
    for @names {
        @first-names.push: $_[0];
        @surenames.push: $_[1];
    }
    return @first-names if @first-names.unique.elems == @first-names.elems;
    return unique-first-names(@first-names, @surenames);
}

sub unique-first-names(@first-names, @surenames, :$surename-abrevated-lenght=1) {
    my Set $repeated = @first-names.repeated.Set;
    gather {
        for @first-names.keys -> $i {
            if @first-names[$i] ∈ $repeated {
                take @first-names[$i] ~ " " ~ @surenames[$i].substr(0,$surename-abrevated-lenght) ~ '.'
            }else{
                take @first-names[$i]
            }
        }
    }
}
sub pick-group-from-class-file(IO(Str) :$class-file, UInt :$group-size, IO(Str) :$pictures-folder?) is export {
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

sub read-file(IO $file) {
    from-json $file.slurp;
}

sub read-group-file(IO(Str) $grouping-file) is export {
    read-file($grouping-file)
}
sub read-placement-file(IO(Str) $placement-file) is export {
    read-file($placement-file)
}

sub create-placement(IO(Str) $class-file, IO(Str) $room-file, IO(Str) $placement-dir, UInt $max-name-width) is export {
    my @not-placed-students = extract-names(get-class($class-file)).pick(*);
    my @room = $room-file.lines.map: { Array.new: $_.comb };

    # pre-process student names
    @not-placed-students = @not-placed-students.map({ .substr(0, $max-name-width) });

    # create placements - by prio
    my @seat-priorities = (1..4).map: *.Str;
    for @seat-priorities -> $prio {
        for ^@room.elems -> $row_id {
            for ^@room[$row_id].elems -> $seat {
                my $marker = @room[$row_id][$seat];
                if $marker eq $prio and @not-placed-students.elems {
                    @room[$row_id][$seat] = @not-placed-students.pop
                }
            }
        }
    }

    # assign X to seats not needed
    for ^@room.elems -> $row_id {
        for ^@room[$row_id].elems -> $seat {
            my $marker = @room[$row_id][$seat];
            if $marker ∈ @seat-priorities {
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
    say "export CRTB_PLACEMENT_FILE=$placement-file-name"
}

sub create-grouping(IO(Str) :$class-file, UInt :$primary-size, UInt :$secondary-size) is export {
    my @students = extract-names(get-class($class-file)).pick(*);
    my $n = @students.elems;

    gather {
        ($secondary-size, $primary-size) Z=> ((0 .. ($n div $secondary-size)) X (0 .. ($n div $primary-size)) andthen
                .first({ (sum $_ >>*<< ($secondary-size,
                                        $primary-size)) == $n })) || note "\nImpossible to split $n students into groups of sizes $primary-size and $secondary-size !!\n" andthen
                .map({
                    my UInt $gsize = .key;
                    my UInt $gcount = .value;
                        for ^$gcount { take @students.splice(0, $gsize)}
                })
    }
}

sub display-grouping(@grouping) is export {
    my $max-elems = max @grouping.map: *.elems;
    my $min-elems = min @grouping.map: *.elems;
    my $pad-elems = $max-elems - $min-elems;

    return if $pad-elems == 0;

    my @padded;
    for @grouping {
        if $_.elems < $max-elems {
            my @p = |$_, |('' xx $pad-elems);
            @padded.push: @p
            }else{
            @padded.push: $_
        }
    }

    print "\n";
    print lol2table(@padded, |%text-table-simple-options).join("\n");
    print "\n";
}

sub save-grouping(@grouping, IO(Str) :$group-folder, IO(Str) :$class-file, UInt :$primary-size, UInt :$secondary-size) is export {
    my $group-file-name = $group-folder.add(join '_', Date.today, $class-file.basename, $primary-size, $secondary-size);
    spurt $group-file-name, to-json @grouping;
    return $group-file-name
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
