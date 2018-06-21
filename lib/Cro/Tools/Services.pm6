use Cro::Tools::CroFile;

class Cro::Tools::Services {
    class Service {
        has IO::Path $.path;
        has Cro::Tools::CroFile $.cro-file;
        has Exception $.cro-file-error;
        has Supply $!file-changed;
        has Promise $!deleted .= new;
        has $!deleted-vow = $!deleted.vow;

        submethod TWEAK(:$!file-changed) {
            self!load-cro-file();
            start react {
                whenever $!file-changed {
                    unless $!path.add('.cro.yml').e {
                        # Some tools rename the file and then save the new one
                        # in its place, so check again later.
                        whenever Promise.in(1) {
                            unless $!path.add('.cro.yml').e {
                                $!deleted-vow.keep(True);
                                done;
                            }
                        }
                    }
                }
            }
        }

        method metadata-changed(--> Supply) {
            supply {
                whenever $!file-changed.grep(*.path eq "$!path/.cro.yml").stable(0.5) {
                    self!load-cro-file();
                    emit .path;
                }
                whenever $!deleted {
                    done;
                }
            }
        }

        method !check-ignore($item) {
            return True if !($!cro-file.defined) || $!cro-file.ignore.elems == 0;
            return !($!cro-file.ignore.ignore-file($item.path) || $!cro-file.ignore.ignore-directory($item.path));
        }

        method source-changed(--> Supply) {
            supply {
                whenever $!file-changed.grep(!*.path.IO.basename.starts-with('.'))
                .grep({ self!check-ignore($_) }) {
                    emit .path;
                }
                whenever $!deleted {
                    done;
                }
            }
        }

        method deleted(--> Promise) {
            $!deleted
        }

        method !load-cro-file() {
            $!cro-file = Cro::Tools::CroFile.parse($!path.add('.cro.yml').slurp);
            CATCH {
                default {
                    $!cro-file = Nil;
                    $!cro-file-error = $_;
                }
            }
        }
    }

    has IO::Path $.base-path is required;

    sub tap-on(Supply:D $supply, Scheduler $scheduler) {
        supply {
            my $worker-emits = Supplier.new;
            whenever $worker-emits -> \message {
                emit message;
            }
            $scheduler.cue: {
                $supply.tap:
                    -> \message { $worker-emits.emit(message) },
                    done => { $worker-emits.done },
                    quit => { $worker-emits.quit($_) }
            }
        }
    }

    method services(--> Supply) {
        supply {
            my class ServiceInfo {
                has $.service;
                has $.file-changed-supplier;
            }
            my %known-services;

            sub maybe-add-service($path) {
                return if %known-services{$path};
                my $file-changed-supplier = Supplier.new;
                my $file-changed = $file-changed-supplier.Supply;
                my $service = Service.new(:$path, :$file-changed);
                %known-services{$path} = ServiceInfo.new(:$service, :$file-changed-supplier);
                emit $service;
            }

            whenever tap-on(self!scan(), $*SCHEDULER) {
                maybe-add-service($_);
            }

            whenever watch-recursive($!base-path) {
                my $path-io = .path.IO;
                next if $path-io.d;
                my $handled = False;
                for %known-services.kv -> $path, $info {
                    if .path.starts-with($path) {
                        $info.file-changed-supplier.emit($_);
                        $handled = True;
                        last;
                    }
                }
                if !$handled {
                    if $path-io.f && $path-io.basename eq '.cro.yml' {
                        maybe-add-service($path-io.parent);
                    }
                }
            }
        }
    }

    method !scan() {
        supply {
            sub search($path) {
                for $path.dir {
                    when .d {
                        search($_) unless .basename.starts-with('.');
                    }
                    when .f {
                        if .basename eq '.cro.yml' {
                            emit $path;
                        }
                    }
                }
            }
            search($!base-path);
        }
    }

    sub watch-recursive(IO::Path $path) {
        supply {
            my %watched-dirs;

            sub add-dir(IO::Path $dir, :$initial) {
                %watched-dirs{$dir} = True;

                whenever $dir.watch {
                    emit $_;
                    my $path-io = .path.IO;
                    when ($path-io.d // False) {
                        unless $path-io.basename.starts-with('.') {
                            add-dir($path-io) unless %watched-dirs{$path-io};
                        }
                    }
                }

                for $dir.dir {
                    unless $initial {
                        emit IO::Notification::Change.new(
                            path => ~$_,
                            event => FileChanged
                        );
                    }
                    when .d {
                        unless .basename.starts-with('.') {
                            add-dir($_, :$initial);
                        }
                    }
                }
            }

            add-dir($path);
        }
    }
}
