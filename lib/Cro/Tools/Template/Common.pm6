use Cro::Tools::CroFile;
use META6;

role Cro::Tools::Template::Common {
    method new-directories($where) { () }

    method entrypoint-contents($id, %options, $links --> Str) { ... }

    method meta6-depends(%options) { ... }

    method meta6-provides(%options) { () }

    method meta6-resources(%options) { () }

    method cro-file-endpoints($id-uc, %options) { ... }


    method make-directories($where) {
        my @dirs = self.new-directories($where);
        .value.mkdir for @dirs;
        @dirs
    }

    method generate-common($where, $id, $name, %options, $generated-links, @links) {
        self.write-entrypoint($where.add('service.p6'), $id, %options, $generated-links);
        self.write-meta($where.add('META6.json'), $name, %options);
        self.write-cro-file($where.add('.cro.yml'), $id, $name, %options, @links);
    }

    method write-entrypoint($file, $id, %options, $links) {
        $file.spurt(self.entrypoint-contents($id, %options, $links));
    }

    method write-meta($file, $name, %options) {
        $file.spurt(self.meta6-object($name, %options).to-json);
    }

    method meta6-object($name, %options) {
        my @depends = self.meta6-depends(%options);
        my %provides = self.meta6-provides(%options);
        my @resources = self.meta6-resources(%options);
        my $m = META6.new(
            :$name, :@depends, :%provides, :@resources,
            description => 'Write me!',
            version => Version.new('0.0.1'),
            perl-version => Version.new('6.*'),
            tags => (''),
            authors => (''),
            auth => 'Write me!',
            source-url => 'Write me!',
            support => META6::Support.new(
                source => 'Write me!'
            ),
            license => 'Write me!'
        );
    }

    method write-cro-file($file, $id, $name, %options, @links) {
        $file.spurt(self.cro-file-object($id, $name, %options, @links).to-yaml);
    }

    method cro-file-object($id, $name, %options, @links) {
        my $id-uc = self.env-name($id);
        my @endpoints = self.cro-file-endpoints($id-uc, %options);
        my $entrypoint = 'service.p6';
        Cro::Tools::CroFile.new(:$id, :$name, :$entrypoint, :@endpoints, :@links)
    }

    method env-name($id) {
        $id.uc.subst(/<-[A..Za..z_]>/, '_', :g)
    }
}
