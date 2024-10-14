unit class App::Classroom::Toolbox:ver<0.0.2>:auth<github:rcmlz>:api<1>;

use experimental :cached;
use variables :D;

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

sub extract-sexs(%class) is export {
    to-lists(%class)[0]
}
sub extract-sure-names(%class) is export {
    to-lists(%class)[1]
}
sub extract-first-names(%class) is export {
    to-lists(%class)[2]
}
sub extract-unique-first-names(%class) is export {
    to-lists(%class)[3]
}
sub extract-emails(%class) is export {
    to-lists(%class)[4]
}

sub to-lists(%class) is cached is export {
    my @sexs;
    my @sure-names;
    my @first-names;
    my @unique-first-names;
    my @emails;
    for %class -> (:$key, :$value) {
        @sexs.push: $value<sex>;
        @sure-names.push: $value<sure-name>;
        @first-names.push: $value<first-name>;
        @unique-first-names.push: $value<unique-first-name>;
        @emails.push: $key;
    }
    return  @sexs, @sure-names, @first-names, @unique-first-names, @emails
}

sub unique-first-names(%class) is export {
    my $max-surename-abrevated-lenght = 1;
    for %class -> (:$key, :$value) {
        $max-surename-abrevated-lenght = max($value<sure-name>.chars, $max-surename-abrevated-lenght)
    }

    my ($sexes, $sure-names, $first-names, $unique-first-names, $emails) = to-lists(%class);
    $unique-first-names = $first-names.unique;

    my %class-adjusted = %class.clone;
    
    my $surename-abrevated-lenght = 0;

    while $first-names.elems != $unique-first-names.elems and $surename-abrevated-lenght <= $max-surename-abrevated-lenght {
        $surename-abrevated-lenght += 1;
        my Set $repeated = $first-names.repeated.Set;
        $unique-first-names = [];
        for $first-names.keys -> $i {
              if $first-names[$i] ∈ $repeated {
                  $unique-first-names[$i] = $first-names[$i] ~ " " ~ $sure-names[$i].substr(0,$surename-abrevated-lenght) ~ '.'
              } else {
                  $unique-first-names[$i] = $first-names[$i]
              }
        }
        $unique-first-names = $unique-first-names.unique
    }
    for ^$emails.elems {
        %class-adjusted{$emails[$_]}<unique-first-name> = $unique-first-names[$_]
    }
    return %class-adjusted
}

sub create-class(IO::Path $class-file) is export {
    my %class;
    my @emails;
    my @first-names;
    my @unique-first-names;
    my @sure-names;

    for $class-file.lines.grep(/^^\w/) -> $entry {
        my ($sex, $sure-name, $first-name, $email) = $entry.split(',').map(*.trim);
        $email = $email.lc;
        %class{$email.lc} = {sex => $sex.lc, sure-name => $sure-name, first-name => $first-name, unique-first-name => $first-name};
        @emails.push: $email.lc;
        @sure-names.push: $sure-name;
        @first-names.push: $first-name;
    }

    %class = unique-first-names(%class);

    for @emails {
        @unique-first-names.push: %class{$_}<unique-first-name>;
    }    

    return $class-file.extension('json') => %class,
           $class-file.extension('emails.txt') => @emails.sort,
           $class-file.extension('first-names.txt') => @first-names.sort,
           $class-file.extension('unique-first-names.txt') => @unique-first-names.sort;
}

sub create-room(IO::Path $room-file) is export {
    my @room = $room-file.lines.map: { Array.new: $_.comb };
    
    return ($room-file.extension('json') => @room,)
}

sub create-placement(%class, @room, Bool $test?) is export {
    my @not-placed-students = %class.keys.pick(*);
    @not-placed-students = %class.keys.sort if $test;

    my @placement = @room.clone;

    # create placements - by prio
    my @seat-priorities = (^10).map: *.Str;
    for @seat-priorities -> $prio {
        for ^@placement.elems -> $row_id {
            for ^@placement[$row_id].elems -> $seat {
                my $marker = @placement[$row_id][$seat];
                if $marker eq $prio and @not-placed-students.elems {
                    my $student = @not-placed-students.shift;
                    @placement[$row_id][$seat] = $student => %class{$student}
                }
            }
        }
    }

    # assign X to seats not needed
    for ^@placement.elems -> $row_id {
        for ^@placement[$row_id].elems -> $seat {
            my $marker = @placement[$row_id][$seat];
            if $marker ∈ @seat-priorities {
                @placement[$row_id][$seat] = "X"
            }
        }
    }
    return placement => @placement, not-placed-students => @not-placed-students
}

sub extract-class-from-placement(@placement) is export {
    my %class;
    for ^@placement.elems -> $row-id {
        for ^@placement[$row-id].elems -> $col-id {
          my $seat = @placement[$row-id][$col-id];
          my $student = $seat.keys.head;
          if $student {
            my %data = $seat{$student};
            %class{$student} = %data
          }
        }
    }
    return %class
}

sub display-placement(@room, :%group = {}, UInt :$max-display-name-width, Bool :$student-view?) is export {
    my @room-view = @room.clone;
    for ^@room-view.elems -> $row-id {
        for ^@room-view[$row-id].elems -> $col-id {
          my $seat = @room-view[$row-id][$col-id];
          if $seat ~~ Hash {
            my $student = $seat.values.head{'unique-first-name'};
            $student = $student.substr(0, $max-display-name-width);
            %group{$seat.keys.head}<unique-first-name-colored> = colored($student, 'red on_blue') if %group{$seat.keys.head}:exists;
            @room-view[$row-id][$col-id] = $student;
          }
        }
    }
    my $return-value = "";
    if $student-view {
        my @placement = lol2table(@room-view, |%text-table-simple-options);
        $return-value = join "\n", create-header(@placement), @placement, create-footer(@placement)
    } else {
        @room-view = @room-view.reverse.map: { Array.new($_.reverse) };
        my @placement = lol2table(@room-view, |%text-table-simple-options);
        $return-value = join "\n", create-footer(@placement), @placement, create-header(@placement)
    }
    for %group.kv -> $student, $data {
        my Str $search = $data<unique-first-name>;
        my Str $replace = $data<unique-first-name-colored>;
        $return-value ~~ s/$search/$replace/;
    }
    return $return-value
}

sub show_pictures(%group, :$pictures-folder1, :$pictures-folder2, UInt :$timeout, Bool :$debug) is export {
    my $pictures-folder = 0;
    $pictures-folder = $pictures-folder1 if so $pictures-folder1 and $pictures-folder1.IO.d;
    $pictures-folder = $pictures-folder2 if (not so $pictures-folder and so $pictures-folder2 and $pictures-folder2.IO.d); 

    return if not $pictures-folder.IO.d;

    with $pictures-folder.IO {
        my @extensions = <.jpg .png>;
        my @emails = extract-emails(%group);
        my @fotos = gather {
            for @emails -> $email {
                my Bool $found = False;
                for @extensions -> $extension {
                    my $foto = $pictures-folder.add($email ~ $extension);
                    if $foto.f {
                        take $foto;
                        $found = True;
                        last
                    }
                }
                note "missing picture: " ~ $pictures-folder.add($email) ~ @extensions.join("|") unless $found
            }
        }
        if @fotos.elems > 0 {
            # uses feh and imagemagick
            my $tool = "feh --multiwindow --scale-down --no-menus --draw-tinted --draw-filename --borderless --auto-zoom --caption-path . --";
            my $cmd = "timeout --signal=HUP --kill-after=" ~ $timeout + 2 ~ " $timeout $tool ";

            # uses MacOS Preview.App
            $cmd = 'open ' if $*DISTRO.Str.contains("macos");
            my Str $shell-cmd = $cmd ~  @fotos.join(" ");
            note $shell-cmd if $debug;
            my $p = shell $shell-cmd;
            $p = True
        }
    }
    return True
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

sub create-grouping(%class, UInt :$primary-size, UInt :$secondary-size) is export {
   my @students = extract-unique-first-names(%class).pick(*);
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

   #return if $pad-elems == 0;

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
   spurt $group-file-name.extension('json'), to-json @grouping;
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
=end code

Start by creating class and room-json files from class and room input files.

=begin code :lang<bash>
crtb-create-class
crtb-create-room
=end code

=begin code :lang<bash>
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
export CRTB_CLASS_FILE=classes/demo-class-large
export CRTB_ROOM_FILE=rooms/demo-room-1
=end code

After you created a placement, grouping or grading you might want to set
=begin code :lang<bash>
export CRTB_PLACEMENT_FILE=placements/demo-placement
export CRTB_GROUP_FILE=groups/demo-grouping
export CRTB_GRADE_FILE=grades/demo-grading
=end code

This usually won't change much - perhaps use direnv to set these automatically
=begin code :lang<bash>
export CRTB_PICTURE_FOLDER=pictures
export CRTB_PLACEMENTS_FOLDER=placements
export CRTB_GRADES_FOLDER=grades
export CRTB_GROUP_FOLDER=groups
=end code

=defn classes/
--class-file= or CRTB_CLASS_FILE=

=defn rooms/ 
--room-file= or CRTB_ROOM_FILE=

=defn pictures/ 
--pictures-folder= or CRTB_PICTURES_FOLDER=

=defn placements/
--placements-file= or export CRTB_PLACEMENT_FILE=placements/demo-placement

=defn grades
t.b.d

=head1 SETUP

=begin code :lang<bash>

git clone https://github.com/zero-overhead/classroom-toolbox
cd classroom-toolbox
zef install .

=end code

=defn feh and imagemagick and timeout
required for showing pictures, install

=begin code :lang<bash>
brew install feh imagemagick coreutils
alias timeout=gtimeout
=end code

=begin code :lang<bash>
nix-shell -p feh imagemagick
=end code

=head1 AUTHOR

rcmlz <19784049+rcmlz@users.noreply.github.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 rcmlz

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
