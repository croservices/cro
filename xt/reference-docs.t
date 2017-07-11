use Test;

sub files($root, $ext) {
    my @paths = $root;
    my @result;

    while @paths {
        for @paths.pop.dir(test => none('.', '..', '.precomp')) -> $path {
            @result.push: $path.relative($root).Str if $path.ends-with($ext);
            @paths.push: $path if $path.d;
        }
    }
    @result;
}

my @code = files($*CWD.IO.child('lib'), '.pm6');
my $docs = set files($*CWD.IO.child('docs/reference'), 'md');

for @code -> $fn {
    ok $docs{$fn.Str.lc.subst('.pm6', '.md').subst('/', '-', :g)}, "$fn is documented";
}

done-testing;
