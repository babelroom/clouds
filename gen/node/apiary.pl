#!/usr/bin/perl

$apiary=0;
foreach(<>) {
    if (/^\/\/\+\+apiary--/) {
        $apiary = !$apiary;
        next;
        }
    if ($apiary) {
        print $_;
        }
    }

