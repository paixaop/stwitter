#
# StealthTwitter
# 
# Author: Pedro Paixao (paixaop@gmail.com) copyright 2009 all rights reserved.
# Based on TwitterShell from Daisuke Maki
#
# This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
# See http://www.perl.com/perl/misc/Artistic.html
# $Id$
package STwitter::Shell::Shell;
use strict;
use warnings;
use base qw(Term::Shell);
use WWW::Shorten 'TinyURL';
use Net::Twitter;
use utf8;

sub context { shift->_elem('context', @_) }
sub prompt_str { shift->_elem('prompt_str', @_) }
sub _elem
{
    my $self = shift;
    my $name = shift;
    my $value = $self->{$name};
    if (@_) {
        $self->{$name} = shift;
    }
    return $value;
}

sub _twitter_cmd
{
    my $self = shift;
    my $cmd  = shift;

    print "Please login first\n"
        if( !$self->context->config->{login} );
        
    $self->paranoid();
    
    my $c    = $self->context;
    my $method = "api_$cmd";
    my $ret    = $c->$method(@_);

    if ($ret) {
        print "$cmd ok\n\n";
    } else {
        print "Command $cmd failed :(\n\n";
    }
    return $ret;
}

sub run_update
{
    my $self = shift;
    my $text = "@_";
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    if ($text) {
        if ($text =~ /\W/) {
            $text .= " ";
        }
    }
    
    # shorten all Urls automatically
    while( $text =~ /(http[s]?:\/\/(?!tinyurl.com)[^ \n]*)/g ) {
        my $url = $1;
        my $short = makeashorterlink($url);
        if( $short ) {
            $text =~ s/(http[s]?:\/\/(?!tinyurl.com)[^ \n]*)/$short/;
        } else {
            print "Warning: Could not shorten $url\n";
        }
    }
    
    # parse for codewords
    foreach my $codeword ( sort keys %{ $self->context->{codewords} } ) {
        my $replace = $self->context->{codewords}->{$codeword};
        $text =~ s/$codeword/$replace/gi
    }
    #print "$text\n";
    $self->_twitter_cmd('update', $text);
}
sub smry_update { "post a message" }

sub help_update {
    my $help =<<EOF;

Send a message update to Twitter.

  update <message>

You can also use the 'say' command.
    
EOF

    return $help;
}

# help
*run_say = \&run_update;
sub smry_say { "alias to 'update'" }
sub help_say {
    my $help =<<EOF;

Send a message update to Twitter.

  say <message>

You can also use the 'update' command.
    
EOF

    return $help;
}


sub run_friends
{
    my $self = shift;  
    my $ret  = $self->_twitter_cmd('friends');

    if ($ret) {
        foreach my $friend (@$ret) {
            printf( "[%s] %s\n", $friend->{screen_name}, $friend->{status}{text});
        }
    }
}
sub smry_friends { "display friends' status" }
sub help_friends { "display friends' status\n" }

sub run_friends_timeline
{
    my $self = shift;
    my $ret  = $self->_twitter_cmd('friends_timeline');

    if ($ret) {
        foreach my $rec (@$ret) {
            utf8::decode($rec->{text});
            printf( "[%s] %s\n\n", $rec->{user}{screen_name}, $rec->{text});
        }
    }
}
sub smry_friends_timeline { "display friends' status as a timeline" }
sub help_friends_timeline { "display friends' status as a timeline\n" }

*run_ft = \&run_friends_timeline;
sub smry_ft { "alias to friends_timeline" }
sub help_ft { "alias to friends_timeline\n" }

sub run_public_timeline
{
    my $self = shift;
    my $ret  = $self->_twitter_cmd('public_timeline');

    if ($ret) {
        foreach my $rec (@$ret) {
            utf8::decode($rec->{text});
            printf( "[%s] %s\n\n", $rec->{user}{screen_name}, $rec->{text});
        }
    }
}

sub smry_public_timeline { "display public status as a timeline" }
sub help_public_timeline { "display public status as a timeline\n" }

*run_pt = \&run_public_timeline;
sub smry_pt { "alias to public_timeline" }
sub help_pt { "alias to public_timeline\n" }

sub run_followers
{
    my $self = shift;
    my $ret  = $self->_twitter_cmd('followers');
    if ($ret) {
        foreach my $rec (@$ret) {
            printf( "[%s] %s\n", $rec->{screen_name}, $rec->{status}{text});
        }
    }
}
sub smry_followers { "display followers' status" }
sub help_followers { "display followers' status\n" }

sub run_mentions
{
    my $self = shift;
    my $ret  = $self->_twitter_cmd('mentions');
    if ($ret) {
        foreach my $rec (@$ret) {
            printf( "[%s] %s\n", $rec->{user}{screen_name}, $rec->{text});
        }
    }
}
sub smry_mentions { "display mentions status" }
sub help_mentions { "display mentions status\n" }

sub run_favorites
{
    my $self = shift;
    my $ret  = $self->_twitter_cmd('favorites');
    if ($ret) {
        foreach my $rec (@$ret) {
            printf( "[%s] %s\n", $rec->{screen_name}, $rec->{status}{text});
        }
    }
}
sub smry_favorites { "display favorites' status" }
sub help_favorites { "display favorites' status\n" }


# Load a file with shell commands, run all commands and stop
sub run_load
{
    my $self = shift;
    my $file = "@_";
    
    $self->paranoid();
    
    if( !open(FIN, "<$file") ) {
        print $file . " could not be loaded\n";
        print "load command failed!\n";
        return;
    }
    print "Loading commands from $file\n";
    while( <FIN> ) {
        my $command = $_;
        chomp $command;
        
        if( $command =~ /exit/i ) {
            print "Terminating\n";
            exit;
        }
        
        $self->cmd($command);
    }
    print "Load completed\n";
}

sub smry_load { "load and run shell commands from file" }
sub help_load {
    my $help =<<EOF;

Load a file with StealthTwit commands and run them one by one.
Each line in the file is a command

Usage:
  load <file_name>
  
If you want to exit if Tor is not running then either set paranoid to On, or
execute the notorexit command as the first command in your file.
Setting paranoid to On may cause huge delays since StealthTwit will check
Tor status before running every command. It is advisable, especially, if you
are in a hurry to use the notoexit command in load operations.

Example file:
   
   notorexit
   say Testing 1, 2, 3
   say Yet another Twitter message
   
   
In this example if Tor is not running none of the other say commands get
executed.

EOF

    return $help;
}

sub run_tor
{
    my $self = shift;
    my $c    = $self->context;
    my $ret  = $c->tor_verify();
}

sub smry_tor { "check if Tor is being used." }
sub help_tor { "check if Tor is being used.\n" }

sub run_notorexit
{
    my $self = shift;
    my $c    = $self->context;
    my $ret    = $c->tor_verify();
    
    if( $ret != 1 ) {
        print "Terminating!\n";
        exit; 
    }
}

sub smry_notorexit { "If Tor is not being used exit SteatlhTwit" }
sub help_notorexit {
    my $help =<<EOF;

Check if Tor is being used when you access Twitter via StealthTwit.
If Tor is not being used exit StealthTwit.

Usage:
  notorexit
  
EOF

    return $help;
}

sub run_paranoid
{
    my $self = shift;
    my $text = "@_";
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    if ($text) {
        if ($text =~ /\W/) {
            $text .= " ";
        }
    }
    
    if( !$text ) {
        my $state = $self->context->config->{paranoid}? "On":"Off";
        print "Paranoid is $state\n";
        return;
    }
    
    if( $text !~ /on|off/i ) {
        print "paranoid on|off";
        return;
    }
    
    if( $text =~ /on/i ) {
        $self->context->config->{paranoid}=1;
        print "paranoid set to on\n";
    } else {
        $self->context->config->{paranoid}=0 if( $text =~ /off/i );
        print "paranoid set to off\n";
    }
}

sub smry_paranoid { "Check if Tor is running before every command" }
sub help_paranoid {
    my $help =<<EOF;

If you have the time and you are a bit paranoid you can have StealthTwit
check Tor connection status before executing any command. This way you are
sure that Tor did not die in between commands and you are still protecting
your privacy.

Once paranoid mode is enabled (on) StealthTwit will exit if at before running
any command if Tor is not being used.

Usage:
  paranoid [on|off]
  
You can also set the paranoid mode in the configuration file. By default
paranoid mode is Off.

EOF

    return $help;
    
}

sub paranoid {
    my $self = shift;
    if( $self->context->config->{paranoid} ) {
        print "Paranoid is On. ";
        my $c = $self->context;
        my $ret = $c->tor_verify();
    
        if( $ret != 1 ) {
            print "Terminating!\n";
            exit; 
        }
    }
}

sub run_codewords
{
    my $self = shift;
    
    if( !defined($self->context->{codewords}) ) {
        print "No code words defined\n";
        return;
    }
    
    print "List of all code words\n";
    foreach my $codeword ( sort keys %{ $self->context->{codewords} } ) {
        print "   " . $codeword . " : " . $self->context->{codewords}->{$codeword} . "\n";
    }
    print "\n";
}

sub smry_codewords { "Show configured code words." }
sub help_codewords {
    my $help =<<EOF;

Code Words are words, or expressions, that get replaced in your messages before
they are sent to Twitter. Imagine you are at work and decide to Twitter about your
Boss, you may not want to type the word "Boss", or a confidential product name.
You can then set up a code word that is replaced by the word "boss" before posting
to Twitter.

Example:
  Girl : Boss

The Code Word "Girl" would be replaced by "Boss" in all messages.

You type: My Gril is very bad
Titter Post: My Boss is very bad

Code Words add a little bit to your privacy and minimize the risk of key loggers,
and shoulder surfing.

You should only edit the codewords file in a secure, trusted, computer.

CodeWords file format:

   <codeword>:<replacement_text>
   
The <codeword> and <replacenent_text> can be whole sentences. Example

   foo:Bar Confidential!
   
Configure the codewords file to use in the configuration file.

EOF

    return $help;
    
}

sub run_username
{
    my $self = shift;

    my $text = "@_";
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    if ($text) {
        if ($text =~ /\W/) {
            $text .= " ";
        }
    }
    
    if( !$text ) {
        my $state = $self->context->config->{username};
        print "Current username is ". $self->context->config->{username} . "\n";
        return;
    }
    
    $self->context->config->{username} = $text;
    print "username set to $text\n";
}

sub smry_username { "set Twitter user name." }
sub help_username { "\n" }

sub run_login {
    my $self = shift;

    $self->paranoid();
    
    # Terminate current session
    $self->context->twitter->end_session;
        
    # Start a new Twitter Session
    $self->context->twitter(Net::Twitter->new(
        username   => $self->context->config->{username},
        password   => $self->context->config->{password},
        clientname => "StealthTwitter",
        clientver  => "1.0",
        clienturl  => "http://code.google.com/p/stwitter/",
        useragent  => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9a1) Gecko/20061204 GranParadiso/3.0a1",
        source     => "stealthtwitter",
    ));

    if( $self->context->twitter->verify_credentials ) {
        print "Login succesful\n";
        $self->context->config->{login} = 1;
    } else {
        print "Could not login. Please verify if the username/password is correct.\n";
        $self->context->config->{login} = 0;
    }
    
}

sub smry_login { "Login to Twitter with current user credenials." }
sub help_login { "\n" }

sub run_password
{
    my $self = shift;

    $self->paranoid();
    
    my $text = "@_";
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    if ($text) {
        if ($text =~ /\W/) {
            $text .= " ";
        }
    }
    
    if( !$text ) {
        my $state = $self->context->config->{password};
        print "Current password is ". $self->context->config->{password} . "\n";
        return;
    }
    
    $self->context->config->{password} = $text;
    print "password set to $text\n";
}

sub smry_password { "set Twitter password." }
sub help_password { "\n" }


1;