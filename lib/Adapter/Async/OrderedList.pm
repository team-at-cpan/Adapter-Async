package Adapter::Async::OrderedList;

use strict;
use warnings;

use parent qw(Adapter::Async);

=pod

Accessing data

count - resolves with the number of items. If this isn't possible, an estimate may be acceptable.

 say "items: " . $adapter->count->get

get - accepts a list of indices

 $adapter->get(
  items   => [1,2,3],
  on_item => sub { ... }
 )->on_done(sub { warn "all done, full list of items: @{$_[0]}" })

The returned list of items are guaranteed not to be modified further, if you want to store the arrayref directly.

This means we have double-notify on get: a request for (1,2,3,4) needs to fire events for each of 1,2,3,4, and also return the list of all of them on completion (by resolving a Future).

Modification

clear - remove all data

splice - modify by adding/removing items at a given point

Helper methods provide the following:

insert - splice $idx, @data, 0

append - splice $idx + 1, @data, 0

Events

All events are shared over a common bus for each data source, in the usual fashion - adapters and views can subscribe to the ones they're interested in, and publish events at any time.

The adapter raises these:

item_changed - the given item has been modified. by default only applies to elements that were marked as visible.

splice - changes to the array which remove or add elements

move - an existing element moves to a new position (some adapters may not be able to differentiate between this and splice: if in doubt, use splice instead, don't report as a move unless it's guaranteed to be existing items)

 index, length, offset (+/-)

The view raises these:

visible - indicates visibility of one or more items. change events will start being sent for these items.

 visible => [1,2,3,4,5,6]

Filters may result in a list with gaps:

 visible => [1,3,4,8,9,10]

Note that "visible" means "the user is able to see this data", so they'd be a single page of data rather than the entire set when no filters are applied. Visibility changes often - scrolling will trigger a visible/hidden pair for example.

Also note that ->get may be called on any element, regardless of visibility - prefetching is one common example here.

hidden - no longer visible.

 hidden => [1,2,4]

selected - this item is now part of an active selection. could be used to block deletes.

 selected => [1,4,5,6]

highlight - mouse over, cursor, etc. 

 highlight => 1

Some views won't raise this - if touch control is involved, for example

activate - some action has been performed.

 activate => [1]
 activate => [1,2,5,6,7,8]

Multi-activate will typically happen when items have been selected rather than just highlighted.

The adapter itself doesn't do much with this.


Transformations

Apply to:
* Row
* Column
* Cell

Row:

This takes the original data item for the row, and returns one of the following:

* Future - when resolved, the items will be used as cells
* Arrayref - holds the cells directly

Returning a Future is preferred.

The data item can be anything - an array-backed adapter would return an arrayref, ORM will give you an object for basic collections.

Any number of cells may be returned from a row transformation, but you may get odd results if the cell count is not consistent.

An array adapter needs no row transformation, due to the arrayref behaviour. You could provide a Future alternative:

 $row->apply_transformation(sub {
  my ($item) = @_;
  Future->wrap(
   @$item
  )
 });

For the ORM example, something like this:

 $row->apply_transformation(sub {
  my ($item) = @_;
  Future->wrap(
   map $item->$_, qw(id name created)
  )
 });

Column:

Column transformations are used to apply styles and formats.

You get an input value, and return either a string or a Future.

Example date+colour transformation on column:

 $col->apply_transformation(sub {
  my $v = shift;
  Future->wrap(
   String::Tagged->new(strftime '%Y-%m-%d', $v)
   ->apply_tag(0, 4, b => 1)
   ->apply_tag(5, 1, fg => 8)
   ->apply_tag(6, 2, fg => 4)
   ->apply_tag(9, 1, fg => 8)
  );
 });

Cell transformations are for cases where you need fine control over individual components. They operate similarly to column transformations,
taking the input value and returning either a string or a Future.

Typical example would be a spreadsheet:

 $cell->apply_transformation(sub {
  my $v = shift;
  return $v unless blessed $v;
  return eval $v if $v->is_formula;
  return $v->to_string if $v->is_formatted;
  return "$v"
 });

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2014. Licensed under the same terms as Perl itself.

