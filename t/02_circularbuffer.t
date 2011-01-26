#!/usr/bin/perl
use strict;
use Test::More;
use Data::CircularBuffer;
use utf8;

$SIG{__WARN__} = sub {};

my $data = Data::CircularBuffer->new(size => 5);
ok $data->is_empty, 'is_empty';
is $data->get_capacity, 5, 'get_capacity';
ok !$data->offer('a'), 'push (not shrinked)';
ok !$data->offer('b'), 'push (not shrinked)';
ok !$data->offer('c'), 'push (not shrinked)';
ok !$data->offer('d'), 'push (not shrinked)';
is_deeply $data->get_data, ['d','c','b','a'], 'is_deeply';
ok !$data->is_full, 'not full';
ok !$data->offer('e'), 'push (not shrinked)';
ok $data->is_full, 'not full';
is_deeply $data->get_data, ['e','d','c','b','a'], 'is_deeply';
ok $data->offer('f'), 'push (shrinked)';
is_deeply $data->get_data, ['f','e','d','c','b'], 'is_deeply';
ok $data->offer('g'), 'push (shrinked)';
is_deeply $data->get_data, ['g','f','e','d','c'], 'is_deeply';

is $data->get_previous(0), 'g', 'previous 0';
is $data->get_previous(1), 'f', 'previous 1';
is $data->get_previous(2), 'e', 'previous 2';
is $data->get_previous(3), 'd', 'previous 3';
is $data->get_previous(4), 'c', 'previous 4';
eval {
    $data->get_previous(5);
    1;
} or do {
    pass 'get_previous 5 fails';
};

# diag('clear');
$data->clear;
is_deeply $data->get_data, [], 'is_deeply';

ok !$data->offer('abc'), 'push (not shrinked)';
ok !$data->offer('def'), 'push (not shrinked)';
is_deeply $data->get_data, ['def', 'abc'], 'is_deeply';
ok !$data->poll, 'pop (not empty)';
is_deeply $data->get_data, ['def'], 'is_deeply';
ok !$data->poll, 'pop (not empty)';
is_deeply $data->get_data, [], 'is_deeply';
ok $data->poll, 'pop (empty)';
ok $data->poll, 'pop (empty)';
is_deeply $data->get_data, [], 'is_deeply';
ok !$data->offer('ghi'), 'push (not shrinked)';
is_deeply $data->get_data, ['ghi'], 'is_deeply';
ok !$data->offer('jkl'), 'push (not shrinked)';
is_deeply $data->get_data, ['jkl', 'ghi'], 'is_deeply';
ok !$data->poll, 'pop (not empty)';
is_deeply $data->get_data, ['jkl'], 'is_deeply';
ok !$data->poll, 'pop (not empty)';
is_deeply $data->get_data, [], 'is_deeply';
ok $data->poll, 'pop (empty)';
is_deeply $data->get_data, [], 'is_deeply';

ok $data->is_empty, 'is_empty';
is $data->get_data_length, 0, 'get_data_length';
ok !$data->offer(111), 'push (not shrinked)';
is $data->get_data_length, 1, 'get_data_length';
ok !$data->offer(222), 'push (not shrinked)';
is $data->get_data_length, 2, 'get_data_length';
ok !$data->offer(333), 'push (not shrinked)';
is $data->get_data_length, 3, 'get_data_length';
ok !$data->offer(444), 'push (not shrinked)';
is $data->get_data_length, 4, 'get_data_length';
ok !$data->is_full, 'is_full';
ok !$data->offer(555), 'push (not shrinked)';
is $data->get_data_length, 5, 'get_data_length';
ok $data->is_full, 'is_full';
is_deeply $data->get_data, [555,444,333,222,111], 'is_deeply';
ok $data->offer(666), 'push (shrinked)';
is_deeply $data->get_data, [666,555,444,333,222], 'is_deeply';
is $data->get_capacity, 5, 'get_capacity';
is $data->get_data_length, 5, 'get_data_length';

$data->expand(10);
is $data->get_capacity, 10, 'get_capacity';
is $data->get_data_length, 5, 'get_data_length';
is_deeply $data->get_data, [666,555,444,333,222], 'is_deeply';
ok !$data->offer(777), 'push (not shrinked)';
is $data->get_data_length, 6, 'get_data_length';
is_deeply $data->get_data, [777,666,555,444,333,222], 'is_deeply';
ok !$data->offer(888), 'push (not shrinked)';
is $data->get_data_length, 7, 'get_data_length';
is_deeply $data->get_data, [888,777,666,555,444,333,222], 'is_deeply';
ok !$data->offer(999), 'push (not shrinked)';
is $data->get_data_length, 8, 'get_data_length';
is_deeply $data->get_data, [999,888,777,666,555,444,333,222], 'is_deeply';
ok !$data->offer(1111), 'push (not shrinked)';
is $data->get_data_length, 9, 'get_data_length';
is_deeply $data->get_data, [1111,999,888,777,666,555,444,333,222], 'is_deeply';
ok !$data->offer(2222), 'push (not shrinked)';
is $data->get_data_length, 10, 'get_data_length';
is_deeply $data->get_data, [2222,1111,999,888,777,666,555,444,333,222], 'is_deeply';
ok $data->offer(3333), 'push (shrinked)';
is $data->get_data_length, 10, 'get_data_length';
is_deeply $data->get_data, [3333,2222,1111,999,888,777,666,555,444,333], 'is_deeply';
ok $data->offer(4444), 'push (shrinked)';
is $data->get_data_length, 10, 'get_data_length';
is_deeply $data->get_data, [4444,3333,2222,1111,999,888,777,666,555,444], 'is_deeply';

my $data2 = $data->clone;

done_testing;
