use Cro::Tools::CroFile;
use META6;

role Cro::Tools::Template::Common {
    method entrypoint-contents($id, %options, $links --> Str) { ... }

    method meta6-object($name, %options --> META6) { ... }

    method cro-file-object($id, $name, %options, @links --> Cro::Tools::CroFile) { ... }


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

    method write-cro-file($file, $id, $name, %options, @links) {
        $file.spurt(self.cro-file-object($id, $name, %options, @links).to-yaml);
    }

    method env-name($id) {
        $id.uc.subst(/<-[A..Za..z_]>/, '_', :g)
    }
}
