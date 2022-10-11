use Cro::Tools::Template;
use File::Find;
use JSON::Fast;

sub get-available-templates($pattern, Supplier $warnings?) is export {
    my @modules-found;

    for $*REPO.repo-chain {
        next unless .can('prefix');
        my $prefix = .prefix;
        when CompUnit::Repository::FileSystem {
            my @files = find(dir => $prefix, name => /\.rakumod?$/);
            @modules-found.append: @files.map:
                *.substr($prefix.chars + 1).subst('/', '::', :g).subst('.rakumod', '');
        }
        when CompUnit::Repository::Installation {
            my $dist_dir = $prefix.child('dist');
            if $dist_dir.?e {
                for $dist_dir.IO.dir.grep(*.IO.f) -> $idx_file {
                    my $data = from-json($idx_file.IO.slurp);
                     @modules-found.append: $data{'provides'}.keys;
                }
            }
        }
    }

    my @template-modules = @modules-found
        .grep(*.starts-with("{$pattern.^name}::"))
        .unique;

    my @templates;
    for @template-modules {
        try require ::($_);
        if $! {
            $warnings.emit(~$!) if $warnings;
            next;
        }
        given ::($_) {
            when $pattern {
                push @templates, $_;
            }
            default {
                .so
            }
        }
    }
    return @templates;
}
