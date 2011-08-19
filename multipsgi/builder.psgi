#!/usr/bin/env perl
use warnings;
use strict;
use Plack::Builder;
use File::Find::Rule;
use Path::Class "file";
use File::Spec;

my $self = file( File::Spec->rel2abs(__FILE__) );

my @app_paths = File::Find::Rule
    ->file()
    ->name( '*.psgi' )
    ->exec( sub { file($self->dir, $_) ne $self } )
    ->in( $self->dir );

my @apps;
for my $app_path ( @app_paths )
{
    print $app_path, $/;
    my $app = do $app_path;
    $app or warn "Couldn't load $app_path\n" and next;
    ref($app) eq "CODE"
        or warn "$app_path did not produce a code ref\n" and next;
    # "app" means "/"

    ( my $path = file($app_path)->relative($self->dir) ) =~ s/\.psgi\z//;
    $path = "/$path";
    $path =~ s/app\z//; # Convert app.psgi to root of its path.

    push @apps, [ $path => $app ];
}

builder { mount $_->[0] => $_->[1] for @apps }

__DATA__

  my $app = builder {
      mount "/foo" => $app1;
      mount "/bar" => builder {
          enable "Plack::Middleware::Foo";
          $app2;
      };
  };
