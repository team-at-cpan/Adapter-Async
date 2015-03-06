package Adapter::Async::UnorderedMap::Hash;

use strict;
use warnings;

use parent qw(Adapter::Async::UnorderedMap);

=head1 NAME

Adapter::Async::UnorderedMap::Hash - hashref adapter

=head1 DESCRIPTION

See L<Adapter::Async::UnorderedMap> for the API.

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->{data} ||= { };
	$self
}

sub clear {
	my $self = shift;
	%{$self->{data}} = ();
	$self->bus->invoke_event('clear');
	Future->wrap
}

# XXX weakrefs
sub move {
	my ($self, $idx, $len, $offset) = @_;
	my @data = splice @{$self->{data}}, $idx, $len;
	splice @{$self->{data}}, $idx + $offset, 0, @data;
	$self->bus->invoke_event(move => $idx, $len, $offset);
	Future->wrap($idx, $len, $offset);
}

# XXX needs updating
sub modify {
	my ($self, $k, $data) = @_;
	die "key does not exist" unless exists $self->{data}{$k};
	$self->{data}{$k} = $data;
	$self->bus->invoke_event(modify => $k, $data);
	Future->wrap
}

sub delete {
	my ($self, $k) = @_;
	delete $self->{data}{$k};
	Future->wrap;
}

=head1 count

=cut

sub count {
	my $self = shift;
	Future->wrap(scalar keys %{$self->{data}});
}

=head1 get

=cut

sub get {
	my ($self, %args) = @_;
	return Future->fail('unknown item') if grep !exists $self->{data}{$_}, @{$args{items}};
	my @items = @{$self->{data}}{@{$args{items}}};
	if(my $code = $args{on_item}) {
		my @k = @{$args{items}};
		$code->(shift(@k), $_) for @items;
	}
	Future->wrap(\@items)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.



