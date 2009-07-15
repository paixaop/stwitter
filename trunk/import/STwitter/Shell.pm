# $Id: /mirror/perl/Twitter-Shell/trunk/lib/Twitter/Shell.pm 7106 2007-05-08T15:08:18.139509Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daiuske@endeworks.jp>
# All rights reserved.

package STwitter::Shell;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp qw(croak);
use Config::General;
use Net::Twitter;
use STwitter::Shell::Shell;
use LWP::UserAgent;


our $VERSION = '0.03';

__PACKAGE__->mk_accessors($_) for qw(shell config twitter);

sub new
{
    my $class = shift;
    my $config = $class->load_config(shift);
    my $self  = $class->SUPER::new();
    $self->config($config);
    $self->setup();
    $self;
}

sub load_config
{
    my $self = shift;
    my $config = shift;
    
    my %config;
    
    if ($config && ! ref $config) {
        my $filename = $config;
        
        print "Using configuration file $filename\n\n";
        
        %config = Config::General::ParseConfig(
            -ConfigFile => $filename,
            -AutoTrue => 1);
        
        if( !%config ) {
            print "Could not read configuration file.\nTerminating\n\n";
            exit;
        }
        
        $config{filename} = $filename;
    } else {
        print "Could not read configuration file.\nTerminating\n\n";
        exit;
    }

    return \%config;
}

sub setup
{
    my $self = shift;
    
    $self->shell(STwitter::Shell::Shell->new);
    
    if( $self->config->{proxy} ) {
        # Force the use of the Proxy in LWP classes used by Net::Twitter and others
        $ENV{'http_proxy'} = $self->config->{proxy};
        $ENV{'https_proxy'} = $self->config->{proxy};
        
        if( $self->config->{verify_tor_onstart} ) {
            my $ret = tor_verify();
            if( $ret != 1 && $self->config->{exit_no_tor} ) {
                print "Terminating!\n";
                exit; 
            }
        }

    } else {
        print "*** WARNING ***\nProxy not configured, please check your configuration file: " .
              $self->config->{filename} . "\n";
        print "Your connection is not private!\n\n";
    }
    
    $self->get_codewords();
        
    $self->twitter(Net::Twitter->new(
        username   => $self->config->{username},
        password   => $self->config->{password},
    ));
    
    if( $self->config->{paranoid} ) {
        print "Paranoid is On. ";
        my $ret = $self->tor_verify();
    
        if( $ret != 1 ) {
            print "Terminating!\n";
            exit; 
        }
    }
    
    if( $self->twitter->verify_credentials ) {
        print "Login succesful\n";
        $self->config->{login} = 1;
    } else {
        print "Could not login. Please verify if the username/password in the configuration file is correct.\n";
        print "Terminating!\n\n";
        exit;
    }
}

sub run
{
    my $self = shift;

    my $shell = $self->shell;
    $shell->context($self);
    $shell->prompt_str('stwit> ');
    
    # Do the autoload from the config file and run the commands
    if( defined($self->config->{load}) ) {
        $shell->cmd("load " . $self->config->{load});
    }
    
    $shell->cmdloop();
}

sub api_update
{
    my $self = shift;
    $self->twitter->update(@_);
}

sub api_friends
{
    my $self = shift;
    $self->twitter->friends();
}

sub api_friends_timeline
{
    my $self = shift;
    $self->twitter->friends_timeline();
}

sub api_public_timeline
{
    my $self = shift;
    $self->twitter->public_timeline();
}

sub api_followers
{
    my $self = shift;
    $self->twitter->followers();
}

sub api_mentions {
    my $self = shift;
    $self->twitter->mentions();
}

sub api_favorites {
    my $self = shift;
    $self->twitter->favorites();
}


sub get_codewords {
    my $self = shift;
    
    
    if( !open(FIN, "<".$self->config->{codewords} ) ) {
        print $self->config->{codewords} . " could not be loaded\n";
        print "No code words loaded.\n";
        return;
    }
    
    while( <FIN> ) {
        my $line = $_;
        chomp $line;
        $line=~ /([^:]*):([^:]*)/;
        my $codeword = $1;
        my $replace =$2;
        $self->{codewords}->{$codeword} = $replace;
    }
    print "Codewords loaded\n";    
}


sub tor_verify {
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    
    print "Checking for Tor. This can take a long time, please wait...\n";
    my $response = $ua->get('http://check.torproject.org/');
    
    if ($response->is_success) {
        if( $response->decoded_content =~ /Congratulations. You are using Tor./ ) {
            print "Tor is in use.\n";
            return 1;
        } else {
            print "*** WARNING ***\nYour connection is not secure.\n";
            return 0;
        }
    } else {
        print "Please check if Tor is running\nYour connection is not secure.\n";
        return -1;
    }
}


1;