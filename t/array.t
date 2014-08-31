use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Adapter::Async::OrderedList::Array;
my $array = new_ok('Adapter::Async::OrderedList::Array');
$array->bus->subscribe_to_event(
	splice => sub {
		my ($ev) = @_;
		fail("Stray event $ev");
		note explain $ev;
	},
	move => sub {
		my ($ev) = @_;
		fail("Stray event $ev");
		note explain $ev;
	},
	clear => sub {
		my ($ev) = @_;
		fail("Stray event $ev");
		note explain $ev;
	},
);
is($array->count->get, 0, 'starts empty');

# Test an insert
$array->bus->subscribe_to_event(
	splice => sub {
		my ($ev, $idx, $len, $data) = @_;
		is($idx, 0, 'splice event for insert had expected index');
		is($len, 0, 'zero length');
		is_deeply($data, ['x'], 'and our expected data');
		$ev->unsubscribe;
		$ev->stop;
	}
);
is(exception {
	$array->insert(0, ['x'])->get
}, undef, 'can insert item');
is($array->count->get, 1, 'now have one item');
is_deeply($array->get(
	items => [0],
	on_item => sub {
		my $item = shift;
		is($item, 'x', 'had expected item in callback');
	}
)->get, ['x'], 'now have one item');

$array->bus->subscribe_to_event(
	splice => sub {
		my ($ev, $idx, $len, $data) = @_;
		is($idx, 1, 'splice event for append had expected index');
		is($len, 0, 'zero length');
		is_deeply($data, [qw(y z)], 'and our expected data');
		$ev->unsubscribe;
		$ev->stop;
	}
);

# Now for an append
is(exception {
	$array->append(0, [qw(y z)])->get
}, undef, 'can append two more items');
is($array->count->get, 3, 'count is now 3');
{
	my @expected = qw(x y z);
	is_deeply($array->get(
		items => [0..2],
		on_item => sub {
			my $item = shift;
			is($item, shift(@expected), 'had expected item in callback');
		}
	)->get, [qw(x y z)], 'have our 3 items');
	is_deeply(\@expected, [], 'callback fired for all expected items');
}

$array->bus->subscribe_to_event(
	move => sub {
		my ($ev, $idx, $len, $offset) = @_;
		is($idx, 2, 'move event had expected index');
		is($len, 1, 'correct length');
		is($offset, -1, 'correct offset');
		$ev->unsubscribe;
		$ev->stop;
	}
);
is(exception {
	$array->move(2, 1, -1)->get
}, undef, 'can move last element back by one');
is($array->count->get, 3, 'count unchanged');

is_deeply($array->get(
	items => [0..2],
)->get, [qw(x z y)], 'elements were reordered');

done_testing;

