#!/usr/bin/perl

$apiary=0;
foreach(<>) {
    if ($apiary and /^\+\+apiary--\*\//) {
        $apiary = 0;
        next;
        }
    elsif (!$apiary && /^\/\*\+\+apiary--/) {
        $apiary = 1;
        next;
        }
    if ($apiary) {
        print $_;
        }
    }

