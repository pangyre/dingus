#!/usr/bin/env perl
use warnings;
use strict;
use Plack::App::URLMap;
use File::Find::Rule;
use Path::Class "file";
use File::Spec;

my $self = file( File::Spec->rel2abs(__FILE__) );

my @app_paths = File::Find::Rule
    ->file()
    ->name( '*.psgi' )
    ->exec( sub { file($self->dir, $_) ne $self } )
    ->in( $self->dir );

my $urlmap = Plack::App::URLMap->new;

for my $app_path ( @app_paths )
{
    my $app = do $app_path;
    $app or die "Couldn't load $app_path\n";
    ref($app) eq "CODE"
        or die "$app_path did not produce a code ref\n";
    # "app" means "/"

    my $rel = file($app_path)->relative($self->dir);
    ( my $path = $rel ) =~ s/\.psgi\z//;
    $path = "/$path";
    $path =~ s,(?:(?<=\w)/)?app\z,,; # Convert app.psgi to root of its path.

    warn sprintf("%25s -> %s\n", $rel, $path);
    $urlmap->map( $path => $app );
}

$urlmap->to_app;

__DATA__
