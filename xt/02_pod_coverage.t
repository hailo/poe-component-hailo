use Test::More;
use Test::Pod::Coverage;

my @modules = all_modules();
plan tests => scalar @modules;
pod_coverage_ok($_) for @modules;
