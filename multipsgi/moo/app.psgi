#!/usr/bin/env perl
sub {
    my $env = shift;
    return [ 200, [ "Content-Type", "text/plain" ], [ "MOOOOOOO" ] ];
}
