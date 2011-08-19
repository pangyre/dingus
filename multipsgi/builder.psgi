#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Builder;
use File::Find::Rule;
use Path::Class "file";
use File::Spec;

my $self = file( File::Spec->rel2abs(__FILE__) );

my @apps = File::Find::Rule
    ->file()
    ->name( '*.psgi' )
    ->exec( sub { file($self->dir, $_) ne $self } )
    ->in( $self->dir );

die join(", ", @apps), $/;

__DATA__
