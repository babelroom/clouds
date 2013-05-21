#!/usr/bin/perl

# ---
# this is an installation helper only to validate that all
# the perl modules have been installed correctly
#
# Do not set -x, execution permission, so that init.pl -u does
# not import it
# ---

use DBI;
use Email::Send;
use IO::Socket::INET;
use POSIX;
use REST::Client;
use String::Random;
use Text::Template;
use Amazon::S3;
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;
use HTTP::Request;
use URI::Escape;
use Email::Send::Gmail;
use Encode;
# should make sure this is 1.43 or greater .... [root@kowloon ~]# cpan -i IO::Socket::SSL 

