use inc::Module::Install;
name 'Data-Versioned';
all_from 'lib/Data/Versioned.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
