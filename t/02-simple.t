use Test::More tests => 2;
use Test::Differences;
BEGIN{
    use_ok('rt::deps', 'silent', ignore => [
        'Test::Builder', 
        'Test::More', 
        'Test::Differences',
    ]);
    push @INC, './t/lib';
}

use test::A;

my $deps = rt::deps::get_deps();
my $expected = {
  main => [
    'test::A'
  ],
  test::A => [
    'test::B'
  ],
  test::B => [
    'test::D'
  ],
  test::D => [
    'test::C'
  ]
};

eq_or_diff( $deps, $expected, "A->[B->D,C]" );