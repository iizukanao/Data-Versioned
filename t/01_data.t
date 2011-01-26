#!/usr/bin/perl
use strict;
use Test::More;
use Data::Versioned;
use utf8;

$SIG{__WARN__} = sub {};

my $data = Data::Versioned->new;
is $data->get_last_rev('a'), 0, 'head rev of a is 0';
$data->set('a', 'c');
is $data->get_last_rev('a'), 1, 'head rev of a is 1';
$data->set('a', 'd');
is $data->get_last_rev('a'), 2, 'head rev of a is 2';
$data->set('a', 'e');
is $data->get_last_rev('a'), 3, 'head rev of a is 3';
is $data->get_last_rev('b'), 0, 'head rev of b is 0';
$data->set('b', 'e');
is $data->get_last_rev('a'), 3, 'head rev of a is 3';
is $data->get_last_rev('b'), 1, 'head rev of b is 1';

my $revs = $data->get_available_revs('a');
is @$revs, 3, '3 revs available';
is_deeply $data->get_data_history('a'), ['e', 'd', 'c'], 'get_data_history()';

is $data->get_rev_data('a', 0), undef, 'rev 0 of a is undef';
is $data->get_rev_data('a', 1), 'c', 'rev 1 of a is c';
is $data->get_rev_data('a', 2), 'd', 'rev 2 of a is d';
is $data->get_rev_data('a', 3), 'e', 'rev 3 of a is e';

$data->replace_rev_data('a', 2, 'あいう');
is $data->get_rev_data('a', 1), 'c', 'rev 1 of a is c';
is $data->get_rev_data('a', 2), 'あいう', 'rev 2 of a is changed';
is $data->get_rev_data('a', 3), 'e', 'rev 3 of a is e';
is_deeply $data->get_data_history('a'), ['e', 'あいう', 'c'], 'get_data_history()';

$data->replace_rev_data('a', 2, 'g');
is $data->get_rev_data('a', 1), 'c', 'rev 1 of a is c';
is $data->get_rev_data('a', 2), 'g', 'rev 2 of a is changed';
is $data->get_rev_data('a', 3), 'e', 'rev 3 of a is e';
is_deeply $data->get_data_history('a'), ['e', 'g', 'c'], 'get_data_history()';

diag('large data');
my $longstr = 'あXx' x 1000000;
$data->replace_rev_data('a', 2, $longstr);
is $data->get_rev_data('a', 2), $longstr, 'rev 2 of a is a long string';

is $data->get_rev_data('a', 4), undef, 'rev 4 of a is undef';

diag('bulk');
$data->set('a', rand(10)) for 1..10;
is $data->get_last_rev('a'), 13, 'head rev of a is 13';
is @{$data->get_available_revs('a')}, 13, '13 revs available';
is @{$data->get_data_history('a')}, 13, '13 items of history available';

$data->set('a', rand(100)) for 1..100;
is $data->get_last_rev('a'), 113, 'head rev of a is 113';
$revs = $data->get_available_revs('a');
is @$revs, 113, '113 revs available';
is $revs->[0], 1, 'oldest available rev is 1';
is $revs->[-1], 113, 'newest available rev is 113';
is @{$data->get_data_history('a')}, 113, '113 items of history available';

diag('delete < 114');
$data->delete_rev_older_than('a', 114);

$revs = $data->get_available_revs('a');
is $data->get_last_rev('a'), 113, 'head rev of a is 113';
is @{$data->get_available_revs('a')}, 0, '0 rev available';
is @{$data->get_data_history('a')}, 0, '0 item of history available';

$data->set('a', rand(1000)) for 1..30;
is $data->get_last_rev('a'), 143, 'head rev of a is 143';
$revs = $data->get_available_revs('a');
is @$revs, 30, '30 revs available';
is $revs->[0], 114, 'oldest available rev is 114';
is $revs->[-1], 143, 'newest available rev is 143';
is @{$data->get_data_history('a')}, 30, '30 items of history available';

diag('delete < 129');
$data->delete_rev_older_than('a', 129);
$revs = $data->get_available_revs('a');
is @$revs, 15, '15 revs available';
is $revs->[0], 129, 'oldest available rev is 129';
is $revs->[-1], 143, 'newest available rev is 143';
is @{$data->get_data_history('a')}, 15, '15 items of history available';

diag('delete < 130');
$data->delete_rev_older_than('a', 130);
$revs = $data->get_available_revs('a');
is @$revs, 14, '14 revs available';
is $revs->[0], 130, 'oldest available rev is 130';
is $revs->[-1], 143, 'newest available rev is 143';
is @{$data->get_data_history('a')}, 14, '14 items of history available';

diag('clear');
$data->clear;
$revs = $data->get_available_revs('a');
is @$revs, 0, '0 rev available';
is @{$data->get_data_history('a')}, 0, '0 item of history available';
is $data->get_rev_data('a', 5), undef, 'rev 5 of a is undef';
eval {
    $data->replace_rev_data('a', 4, 'dfg'); # fails
    1;
} or do {
    pass 'replace_rev_data fails';
};
is $data->get_rev_data('a', 4), undef, 'rev 4 of c is undef';
is @$revs, 0, '0 rev available';
is @{$data->get_data_history('a')}, 0, '0 item of history available';

$data->set('a', rand(10)) for 1..10;
$revs = $data->get_available_revs('a');
is @$revs, 10, '10 revs available';
is @{$data->get_data_history('a')}, 10, '10 items of history available';

is $data->get_last_rev('a'), 10, 'last rev is 10';

diag('clear_revs');
$data->clear_revs('a');
$revs = $data->get_available_revs('a');
is @$revs, 0, '0 rev available';
is @{$data->get_data_history('a')}, 0, '0 item of history available';

is $data->get_last_rev('a'), 10, 'last rev is 10';

$data->set('a', rand(10)) for 1..10;
$revs = $data->get_available_revs('a');
is @$revs, 10, '10 revs available';
is @{$data->get_data_history('a')}, 10, '10 items of history available';

is $data->get_last_rev('a'), 20, 'last rev is 20';

diag('remove');
$data->remove('a');
is $data->get_last_rev('a'), 0, 'last rev is 0';
$revs = $data->get_available_revs('a');
is @$revs, 0, '0 rev available';
is @{$data->get_data_history('a')}, 0, '0 item of history available';

done_testing;
