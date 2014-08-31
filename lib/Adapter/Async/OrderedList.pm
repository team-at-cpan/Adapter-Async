package Adapter::Async::OrderedList;

use strict;
use warnings;

use parent qw(Adapter::Async);

=head1 NAME

Adapter::Async::OrderedList - API for dealing with ordered lists

=head1 DESCRIPTION

=head2 Accessing data

=over 4

=item * count - resolves with the number of items. If this isn't possible, an estimate may be acceptable.

 say "items: " . $adapter->count->get

=item * get - accepts a list of indices

 $adapter->get(
  items   => [1,2,3],
  on_item => sub { ... }
 )->on_done(sub { warn "all done, full list of items: @{$_[0]}" })

The returned list of items are guaranteed not to be modified further, if you want to store the arrayref directly.

=back

This means we have double-notify on get: a request for (1,2,3,4) needs to fire events for each of 1,2,3,4, and also return the list of all of them on completion (by resolving a Future).

=head2 Modification

=over 4

=item * clear - remove all data

=item * splice - modify by adding/removing items at a given point

=back

Helper methods provide the following:

=over 4

=item * insert - splice $idx, @data, 0

=item * append - splice $idx + 1, @data, 0

=back

=head2 Events

All events are shared over a common bus for each data source, in the usual fashion - adapters and views can subscribe to the ones they're interested in, and publish events at any time.

The adapter raises these:

=over 4

=item * item_changed - the given item has been modified. by default only applies to elements that were marked as visible.

=item * splice - changes to the array which remove or add elements

=item * move - an existing element moves to a new position (some adapters may not be able to differentiate between this and splice: if in doubt, use splice instead, don't report as a move unless it's guaranteed to be existing items)

 index, length, offset (+/-)

=back

The view raises these:

=over 4

=item * visible - indicates visibility of one or more items. change events will start being sent for these items.

 visible => [1,2,3,4,5,6]

Filters may result in a list with gaps:

 visible => [1,3,4,8,9,10]

Note that "visible" means "the user is able to see this data", so they'd be a single page of data rather than the entire set when no filters are applied. Visibility changes often - scrolling will trigger a visible/hidden pair for example.

Also note that ->get may be called on any element, regardless of visibility - prefetching is one common example here.

=item * hidden - no longer visible.

 hidden => [1,2,4]

=item * selected - this item is now part of an active selection. could be used to block deletes.

 selected => [1,4,5,6]

=item * highlight - mouse over, cursor, etc. 

 highlight => 1

Some views won't raise this - if touch control is involved, for example

=item * activate - some action has been performed.

 activate => [1]
 activate => [1,2,5,6,7,8]

Multi-activate will typically happen when items have been selected rather than just highlighted.

The adapter itself doesn't do much with this.

=back

=cut

sub insert {
	my ($self, $idx, $data) = @_;
	$self->splice($idx, 0, $data)
}

sub append {
	my ($self, $idx, $data) = @_;
	$self->splice($idx + 1, 0, $data)
}

sub push {
	my ($self, $data) = @_;
	$self->count->then(sub {
		$self->splice(shift, 0, $data)
	})
}

sub unshift {
	my ($self, $data) = @_;
	$self->splice(0, 0, $data)
}

sub pop {
	my ($self, $data) = @_;
	$self->count->then(sub {
		$self->splice(shift, 1)
	})
}

sub unshift {
	my ($self, $data) = @_;
	$self->splice(0, 1)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2014. Licensed under the same terms as Perl itself.

