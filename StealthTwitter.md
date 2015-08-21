# Introduction #

StealthTwitter allows fast, and private, access to Twitter by combining the power
and privacy of Tor (http://www.torproject.org/) with a command line Twitter client.

The goal of StealthTwitter is not to be a beautiful and graphical, but stealth, fast
and automated.

You can post dozens of Twitts, get friend status, and time line, automatically
and privately without having to type a single key.
This is important if you are accessing Twitter from an untrusted computer, that
may be running key loggers.

Connections to Twitter are made through, a secure and private Tor connection, your
IP address, or identity will not be revealed.

# Requirements #

  * Perl 5.8
    * Config::General
    * Net::Twitter
    * LWP::UserAgent
    * WWW::Shorten
    * Term::Shell
    * Getopt::Long
  * Tor
  * Privoxy

You can get all the necessary Perl modules from [CPAN](http://search.cpan.org).

# Privacy Notes #

StealthTwitter is only stealthy and private if you are using Tor or a similar technology to connect to the Internet. It you do not have Tor properly configured you may be leaking information that can compromise your posts.
It is important to note that the program checks if Tor is running by accessing http://check.torproject.org/. If Tor is not running, or if it is not properly configured your access to the "Tor validation" site may be logged and you can be exposed.

Always test your configuration in a trusted environment before you venture out into the "real world".

# Tor #

For more information on how Tor works please visit https://www.torproject.org/index.html.en

The easiest way to get Tor is to download it from https://www.torproject.org/download.html.en

If you want to run StealthTwitter from a USB drive in conjunction with Tor please read http://portabletor.sourceforge.net/


# Command Line Options #

## --config | -c ##

Specify the config file to read from. By default, StealthTwit attempts to read
a config file named _stwit.conf_ in the current directory

## --help | -h ##

Print out this help message and exit

# Configuration File #

The StealthTwitter configuration file is a simple text file that configures the
following options:

## username = your@email.address ##

Your Twitter user name

## password = your\_password ##

your Twitter password

## codewords = codeword\_file ##

Codewords file allows you to setup keywords, or expressions, that get translated
into the real words before the message is posted. This helps to avoid
incrimination by the use of key loggers in systems you do not control.

Example:

```
Code word   Translation
Girl        Boss
```

now if your message is: my girl is an ass
translation: my Boss is an ass

The code word file defines a code word, and translation/replacement expression
per line separated by ':'.

Example

```
girl:boss
france:iran
```

## load = autoload.txt ##

Load a file with StealthTwitter commands and run them one by one.
Each line in the file is a command

Usage:
```
load file_name
```

If you want to exit if Tor is not running then either set _paranoid_ to On, or
execute the _notorexit_ command as the first command in your file.
Setting _paranoid_ to On may cause huge delays since StealthTwitter will check
Tor status before running every command. It is advisable, especially, if you
are in a hurry to use the _notorexit_ command in load operations.

Example file:
```
notorexit
say Testing 1, 2, 3
say Yet another Twitter message
```

In this example if Tor is not running none of the other say commands get
executed.

## proxy = http://server:port ##

Tor/Privoxy proxy server URL. Usually http://127.0.0.1:8118
Tor is a Socks proxy not an HTTP proxy, so you should use Privoxy or another proxy server to relay your data through Tor.

## verify\_tor\_onstart = true|false ##

Verify if Tor is running at the start of StealthTwitter

## exit\_no\_tor = true|false ##

If _verify\_tor\_onstart_, and  _exit\_no\_tor_ are enabled StealthTwitter will exit
if Tor connection status is not up.

## paranoid = false|false ##

In paranoid mode, StealthTwitter will check Tor status before running any command.
if Tor connection status is not up StealthTwit will exit immediately

# Shell Mode #

If your autoload command file does not contain an exit command, or you have no
autoload file configured StealthTwitter will run in shell mode where you can
interactively type Twitter commands.

In the interactive shell environment you can execute the following commands

```
codewords        - Show configured code words.
exit             - exits the program
followers        - display followers' status
friends          - display friends' status
friends_timeline - display friends' status as a timeline
ft               - alias to friends_timeline
help             - prints this screen, or help on command
load             - load and run shell commands from file
login            - Login to Twitter with current user credentials.
notorexit        - If Tor is not being used exit SteatlhTwitter
paranoid         - Check if Tor is running before every command
password         - set Twitter password.
pt               - alias to public_timeline
public_timeline  - display public status as a timeline
say              - alias to 'update'
tor              - check if Tor is being used.
update           - post a message
username         - set Twitter user name.
```

Any of these commands may be used in a command file and executed in batch mode.
Although commands are very simple and short the shell environment does support TAB
command completion.

To get detailed help on any command use the _help_ command.

To exit StealthTwitter type _exit_

# Identities #

By default StealthTwitter uses the configuration file set credentials in order
to login to Twitter. But you can also switch Twitter accounts with the _username_
and _password_ commands, followed by a _login_ command.

A _login_ command forces the logout of previous user.

Example:

```
    say Status update for config file user credentials
    username newuser
    password newpassword
    login
    say Status update for newuser!
```

# URL Shortening #

By default all URLs are automatically shortened using TinyURL.com service.

# Author #

Pedro Paixao Copyright 2009

Based on Twitter::Shell parts of the code are:
Gungho is Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp> Endeworks Ltd.
All rights reserved.

# License #
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See http://www.perl.com/perl/misc/Artistic.html