use v6;

use Test;

use lib '.';

# test that packages work.  Note that the correspondance between type
# objects as obtained via the ::() syntax and packages is only hinted
# at in L<S10/Packages/or use the sigil-like>
plan 23;

# 4 different ways to be imported
# L<S10/Packages/A bare>
{
    package Test1 {
        our sub ns  { "Test1" }
        our sub pkg { $?PACKAGE }
        our sub test1_export is export { "export yourself!" }
    }
    package Test2 {
        our sub ns { "Test2" }
        our sub pkg { $?PACKAGE }
        our $scalar = 42;
    }
    package Test3 {
        our sub pkg { $?PACKAGE }
    }
}

use t::spec::packages::PackageTest;

# test that all the functions are in the right place

# sanity test
# L<S10/Packages/package for Perl>
is($?PACKAGE, "Main", 'The Main $?PACKAGE was not broken by any declarations');

# block level
is(Test1::ns, "Test1", "block-level package declarations");
cmp-ok(Test1::pkg, &infix:<===>, ::Test1::, 'block-level $?PACKAGE var');
dies-ok { EVAL 'test1_export' }, "export was not imported implicitly";

# declared packages
is(Test2::ns, "Test2", "declared package");
cmp-ok(Test2::pkg, &infix:<===>, ::Test2::, 'declared package $?PACKAGE');

# string EVAL'ed packages
is(Test3::pkg, ::Test3::, 'EVAL\'ed package $?PACKAGE');
cmp-ok(Test3::pkg, &infix:<===>, ::Test3::, 'EVAL\'ed package type object');

# this one came from t/packages/Test.pm
is(t::spec::packages::PackageTest::ns, "t::packages::PackageTest", "loaded package");
cmp-ok(t::spec::packages::PackageTest::pkg, &infix:<===>, ::t::packages::PackageTest::, 'loaded package $?PACKAGE object');
my $x;
lives-ok { $x = test_export() }, "export was imported successfully";
is($x, "party island", "exported OK");

# exports
dies-ok { ns() }, "no ns() leaked";

# now the lexical / file level packages...
my $pkg;
dies-ok  { $pkg = Our::Package::pkg },
    "Can't see `our' packages out of scope";
lives-ok { $pkg = t::spec::packages::PackageTest::get_our_pkg() },
    "Package in scope can see `our' package declarations";
is($pkg, Our::Package, 'correct $?PACKAGE');
ok(!($pkg === ::Our::Package),
   'not the same as global type object');

# oh no, how do we get to that object, then?
# perhaps %t::spec::packages::PackageTest::<Our::Package> ?

dies-ok { $pkg = t::spec::packages::PackageTest::cant_see_pkg() },
    "can't see package declared out of scope";
lives-ok { $pkg = t::spec::packages::PackageTest::my_pkg() },
    "can see package declared in same scope";
is($pkg, ::My::Package::, 'correct $?PACKAGE');
ok($pkg !=== ::*My::Package::, 'not the same as global type object');

# Check temporization of variables in external packages
{
  {
    ok(EVAL('temp $Test2::scalar; 1'), "parse for temp package vars");
    $Test2::scalar++;
  }
  is($Test2::scalar, 42, 'temporization of external package variables');
}

# vim: ft=perl6
