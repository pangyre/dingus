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
    my $app = do $app_path or die "Couldn't load $app_path\n";
    ref $app eq "CODE"
        or die "$app_path did not produce a code ref\n";

    # "./app.psgi" means "./"
    my $rel = file($app_path)->relative($self->dir);
    ( my $path = $rel ) =~ s/\.psgi\z//;
    $path = "/$path";
    $path =~ s,(?:(?<=\w)/)?app\z,,; # Convert app.psgi to root of its path.

    warn sprintf("%35s -> %s\n", $rel, $path);
    $urlmap->map( $path => $app );
}

$urlmap->to_app;

__DATA__

=pod

=head1 Name

multi.psgi - a proof of concept for maintaining psgi apps in a file tree mapping to their web locations.

=head1 Synopsis

 apv[1186]~/depot/dingus/multipsgi>find .
 .
 ./app.psgi
 ./hello.psgi
 ./moo
 ./moo/app.psgi
 ./moo/cow.psgi
 ./multi.psgi
 ./README.pod

 apv[1187]~/depot/dingus/multipsgi>plackup multi.psgi
                            app.psgi -> /
                          hello.psgi -> /hello
                        moo/app.psgi -> /moo
                        moo/cow.psgi -> /moo/cow
 HTTP::Server::PSGI: Accepting connections at http://0:5000/

Put the multi.psgi into a tree with other psgis and run it. It
discovers them and loads them at the URL corresponding to the place in
the file tree. The name C<app.psgi> is truncated to its root. You can
see this in action above, e.g.: C<moo/app.psgi> -E<gt> C</moo>. Other
names become a part of the dispatch path, e.g.: C<moo/cow.psgi> -E<gt>
C</moo/cow>.

=head2 Note

A lack of psgis other than C<multi.psgi> won't cause an error, you'll
just an app made of 404 FAIL. Until you drop in a psgi and HUP the
server, anyway.

=head1 Author

Ashley Pond V E<middot> ashley@cpan.org E<middot>
L<http://pangyresoft.com>.

=head1 License

You may redistribute and modify this package under the same terms as
Perl itself.

=head1 Disclaimer of Warranty

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut
