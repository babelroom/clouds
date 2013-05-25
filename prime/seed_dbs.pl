#!/usr/bin/perl

# currently unused but good reference for certain type of importer ...

use Data::Dumper;
use YAML;
use lib '/home/br/gits/clouds/netops/br_scripts';
use BRDB;




my $dbh = db_connect('dbi:mysql:netops:127.0.0.1:3306', 'root', '','BOOTSTRAP');
print Dumper($dbh);


# Load a YAML stream of 3 YAML documents into Perl data structures.
my ($hashref, $arrayref, $string) = Load(<<'...');
---
name: ingy
age: old
weight: heavy
# I should comment that I also like pink, but don't tell anybody.
favorite colors:
    - red
    - green
    - blue
---
- Clark Evans
- Oren Ben-Kiki:
    foo: bar
- Ingy döt Net
--- >
You probably think YAML stands for "Yet Another Markup Language". It
ain't! YAML is really a data serialization language. But if you want
to think of it as a markup, that's OK with me. A lot of people try
to use XML as a serialization format.

"YAML" is catchy and fun to say. Try it. "YAML, YAML, YAML!!!"
...

# Dump the Perl data structures back into YAML.
print Dump($string, $arrayref, $hashref);
print Dumper($string, $arrayref, $hashref);

