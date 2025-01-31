#!/usr/bin/env raku
use v6.e.PREVIEW; #for .nomark
use App::Classroom::Toolbox;
use JSON::Fast;

# we go with .nomarks for the time beeing
#my %homoglyphs = 
#    'ž' => 'z',
#    'ě' => 'e',
#    'é' => 'e',
#;

#| Creates Obsidian Flash Cards
sub MAIN(IO::Path(Str) :c(:$class-file) where *.f = %*ENV<CRTB_CLASS_FILE>, #= file containing students information; --class-file=classes/demo-class-small or 'export CRTB_CLASS_FILE=classes/demo-class-small'
         IO::Path(Str) :b(:$base-dir), #= when generating the mkdir commands, we need a absolute base dir, like /home/httpd/vhosts/user/path
    ) {
    my %class = from-json $class-file.extension('json').slurp;
    my $Klasse = $class-file.basename;
    
    my %passwords;
    for %class.keys.sort -> $email {
        my $data = %class{$email};
        my $name = $data<unique-first-name>.lc.subst(/\s/, "_", :g).subst(/\./, "", :g);

        # if $name contains none-ascii chars, map to ascii homoglyphs
        #$name = $name.comb.map( -> $char { ord($char) < 128 ?? $char !! %homoglyphs{$char} || die "No homoglyph for $char" }).join;
        $name = $name.nomark;

        my $random-integer = (10**15 .. 10**22).roll;
        my $passwd = $random-integer;
        my $proc = shell "openssl passwd -6 $passwd", :out;
        my $encr = $proc.out.slurp: :close;
        my $path = "content/$Klasse/" ~ $name;
        %passwords{"$Klasse-$name"} = $passwd, $encr.chomp, $email, $name, $path;
    }

    die "unique-first-name clash induced by Str.nomark" unless %passwords.keys.elems == %class.keys.elems;

    say "\nput into tinyfilemanager access config - e.g. auth/tfm-SCHOOL-KLASS.php-template:\n";
    say q:to/PHP/;
<?php
// Users: array('Username' => 'Password', 'Username2' => 'Password2', ...)
// Generate secure password hash - https://tinyfilemanager.github.io/docs/pwd.html
// "openssl passwd -6 $passwd"
$auth_users = array_merge($auth_users, array(
PHP
    # user credentials
    for %passwords.keys.sort -> $user {
        say "'$user' => '{%passwords{$user}[1]}', // {%passwords{$user}[0]}"
    }
    say q:to/PHP/;
));

// user specific directories
// array('Username' => 'Directory path', 'Username2' => 'Directory path', ...)
$directories_users = array_merge($directories_users, array(
PHP 
    # path restrictions
    for %passwords.keys.sort -> $user {
        say "'$user' => '{%passwords{$user}[4]}',"
    }
    say q:to/PHP/;
));
?>
PHP

    # folder creation
    say "\nExecute on webserver to create the students folders and .htaccess file:\n";
    my @dirs-to-create;
    for %passwords.keys.sort -> $user {
        @dirs-to-create.push: $base-dir.add(%passwords{$user}[4])
    }
    print "mkdir -pv {@dirs-to-create.join(' ')};";
    say " echo 'Options +Indexes' > {$base-dir.add('content',$Klasse,'.htaccess')};";

    # for sending to students
    say "\nSend to students via Email:\n";
    for %passwords.keys.sort -> $user {
        say "{%passwords{$user}[2]}, $user, {%passwords{$user}[0]}, {%passwords{$user}[4]}"
    }
    say "";
}