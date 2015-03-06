use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Adapter::Async::UnorderedMap::Hash;

my $hash = new_ok('Adapter::Async::UnorderedMap::Hash');
is($hash->count->get, 0, 'starts empty');

done_testing;
