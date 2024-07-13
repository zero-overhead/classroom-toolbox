unit class App::Classroom::Toolbox::Timer:ver<0.0.1>:auth<github:rcmlz>:api<1>;

use P5localtime;
use Terminal::Print;

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

sub run-timer(UInt:D $minutes, Bool $skip-wait) is export {
    my $screen = Terminal::Print.new;
    $screen.initialize-screen;
    timer($screen, $minutes, $skip-wait);
    $screen.shutdown-screen;
}
sub timer(\Terminal, $minutes, Bool $skip-wait) {
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

    unless $skip-wait {
        Terminal.print-string( $x, $y, " Hit enter ");
        prompt
    }
}

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