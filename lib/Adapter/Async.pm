package Adapter::Async;
# ABSTRACT: common API for linking data sources and views
use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

Adapter::Async -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Future;
use curry;

use Adapter::Async::Bus;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class
}

sub bus { shift->{bus} ||= Adapter::Async::Bus->new }

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.

