use Test::More tests => 2;
use Test::Differences;
BEGIN{
    use_ok('rt::deps', 'silent', ignore => [
      'Test::Builder', 
      'Test::More', 
      'Test::Differences',
    ]);
}

my $deps = rt::deps::get_deps();
my $expected = {};
eq_or_diff( $deps, $expected, "no deps" );