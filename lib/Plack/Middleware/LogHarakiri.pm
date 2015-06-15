package Plack::Middleware::LogHarakiri;
use parent qw/ Plack::Middleware Process::SizeLimit::Core /;

$Plack::Middleware::LogHarakiri::VERSION = '0.0100';

=head1 NAME

Plack::Middleware::LogHarakiri - log when a process is killed

=for readme plugin version

=head1 SYNOPSIS

  use Plack::Builder;

  builder {

    enable "LogHarakiri";
    enable "SizeLimit",  ...;

    $app;
  };

=begin :readme

=head1 INSTALLATION

See
L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>.

=for readme plugin requires heading-level=2 title="Required Modules"

=for readme plugin changes

=end :readme


=head1 DESCRIPTION

This middleware is a companion to L<Plack::Middleware::SizeLimit> that
emits a warning when a process is killed.

When it detects that the current process is killed, it will emit a
warning with diagnostic information.

Note that this middleware must be enabled before plugins that set the
"harakiri" flag.

=head1 SEE ALSO

L<PSGI::Extensions>

=head1 AUTHOR

Robert Rothenberg C<< rrwo@thermeon.com >>

=head1 COPYRIGHT

Copyright 2015, Thermeon Worldwide, PLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);

    return $res
        unless $env->{'psgix.harakiri'} or $env->{'psgix.harakiri.supported'};

    my $harakiri = $env->{'psgix.harakiri.supported'} ? # Legacy
        $env->{'psgix.harakiri'} :
        $env->{'psgix.harakiri.commit'};

    if ($harakiri) {
        my $message = sprintf(
            'pid %d committed harakiri (size: %d, shared: %d, unshared: %d)',
            $$, $self->_check_size
            );
        if (my $logger = $env->{'psgix.logger'}) {
            $logger->( { message => $message, level => 'warn' } );
            }
        else {
            warn "$message\n";
            }
        }

    return $res;
    };

1;
