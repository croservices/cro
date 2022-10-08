use Cro::Tools::CroFile;
use Test;

{
    my $parsed;
    lives-ok { $parsed = Cro::Tools::CroFile.parse: q:to/YAML/ }, 'Minimal file parses';
        cro: 1
        id: flashcard-backend
        name: Flashcards Backend
        entrypoint: service.p6
        YAML
    is $parsed.id, 'flashcard-backend', 'Correct id';
    is $parsed.name, 'Flashcards Backend', 'Correct name';
    is $parsed.entrypoint, 'service.p6', 'Correct entrypoint';
}

{
    my $parsed;
    lives-ok { $parsed = Cro::Tools::CroFile.parse: q:to/YAML/ }, 'File without name parses';
        cro: 1
        id: flashcard-backend
        entrypoint: service.p6
        YAML
    is $parsed.id, 'flashcard-backend', 'Correct id';
    is $parsed.name, 'flashcard-backend', 'Correct name (defaulted to id)';
    is $parsed.entrypoint, 'service.p6', 'Correct entrypoint';
}

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    name: Flashcards Backend
    id: flashcard-backend
    entrypoint: service.p6
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'cro',
   'Cannot cope with missing cro field';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    name: Flashcards Backend
    entrypoint: service.p6
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'id',
   'Cannot cope with missing id field';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    name: Flashcards Backend
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'entrypoint',
   'Cannot cope with missing entrypoint field';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    name: Flashcards Backend
    entrypoint: service.p6
    wat: courgette
    YAML
    X::Cro::Tools::CroFile::Unexpected, field => 'wat',
   'Unexpected field is an error';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 2
    id: flashcard-backend
    name: Flashcards Backend
    entrypoint: service.p6
    YAML
    X::Cro::Tools::CroFile::Version, got => '2',
   'Unrecognized version is an error';

{
    my $parsed;
    lives-ok { $parsed = Cro::Tools::CroFile.parse: q:to/YAML/ }, 'Endpoints parse';
        cro: 1
        id: flashcard-backend
        entrypoint: service.p6
        endpoints:
        - id: http
          name: HTTP (Insecure)
          protocol: http
          host-env: FLASHCARD_BACKEND_HTTP_HOST
          port-env: FLASHCARD_BACKEND_HTTP_PORT
        - id: https
          protocol: https
          host-env: FLASHCARD_BACKEND_HTTPS_HOST
          port-env: FLASHCARD_BACKEND_HTTPS_PORT
        YAML
    is $parsed.endpoints.elems, 2, 'Parsed 2 endpoints';
    given $parsed.endpoints[0] {
        is .id, 'http', 'Correct endpoint id (1)';
        is .name, 'HTTP (Insecure)', 'Correct endpoint name (1)';
        is .protocol, 'http', 'Correct endpoint protocol (1)';
        is .host-env, 'FLASHCARD_BACKEND_HTTP_HOST', 'Correct endpoint host-env (1)';
        is .port-env, 'FLASHCARD_BACKEND_HTTP_PORT', 'Correct endpoint port-env (1)';
    }
    given $parsed.endpoints[1] {
        is .id, 'https', 'Correct endpoint id (2)';
        is .name, 'https', 'Correct endpoint name defaulted from id (2)';
        is .protocol, 'https', 'Correct endpoint protocol (2)';
        is .host-env, 'FLASHCARD_BACKEND_HTTPS_HOST', 'Correct endpoint host-env (2)';
        is .port-env, 'FLASHCARD_BACKEND_HTTPS_PORT', 'Correct endpoint port-env (2)';
    }
}

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    endpoints:
    - protocol: http
      host-env: FLASHCARD_BACKEND_HTTP_HOST
      port-env: FLASHCARD_BACKEND_HTTP_PORT
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'id', in => 'entrypoint',
   'Cannot cope with missing id field in entrypoint';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    endpoints:
    - id: http
      host-env: FLASHCARD_BACKEND_HTTP_HOST
      port-env: FLASHCARD_BACKEND_HTTP_PORT
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'protocol', in => 'entrypoint',
   'Cannot cope with missing protocol field in entrypoint';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    endpoints:
    - id: http
      protocol: http
      port-env: FLASHCARD_BACKEND_HTTP_PORT
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'host-env', in => 'entrypoint',
   'Cannot cope with missing host-env field in entrypoint';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    endpoints:
    - id: http
      protocol: http
      host-env: FLASHCARD_BACKEND_HTTP_HOST
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'port-env', in => 'entrypoint',
   'Cannot cope with missing port-env field in entrypoint';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    endpoints:
    - id: http
      protocol: http
      host-env: FLASHCARD_BACKEND_HTTP_HOST
      port-env: FLASHCARD_BACKEND_HTTP_PORT
      wat: pineapple
    YAML
    X::Cro::Tools::CroFile::Unexpected, field => 'wat', in => 'entrypoint',
   'Unexpected entrypoint field is an error';

{
    my $parsed;
    lives-ok { $parsed = Cro::Tools::CroFile.parse: q:to/YAML/ }, 'Links parse';
        cro: 1
        id: flashcard-backend
        entrypoint: service.p6
        links:
          - service: flashcard-backend
            endpoint: https
            host-env: FLASHCARD_BACKEND_HTTPS_HOST
            port-env: FLASHCARD_BACKEND_HTTPS_PORT
          - service: users
            endpoint: https
            host-env: USERS_HTTPS_HOST
            port-env: USERS_HTTPS_PORT
        YAML
    is $parsed.links.elems, 2, 'Parsed 2 links';
    given $parsed.links[0] {
        is .service, 'flashcard-backend', 'Correct link service (1)';
        is .endpoint, 'https', 'Correct link endpoint (1)';
        is .host-env, 'FLASHCARD_BACKEND_HTTPS_HOST', 'Correct link host-env (1)';
        is .port-env, 'FLASHCARD_BACKEND_HTTPS_PORT', 'Correct link port-env (1)';
    }
    given $parsed.links[1] {
        is .service, 'users', 'Correct link service (2)';
        is .endpoint, 'https', 'Correct link endpoint (2)';
        is .host-env, 'USERS_HTTPS_HOST', 'Correct link host-env (2)';
        is .port-env, 'USERS_HTTPS_PORT', 'Correct link port-env (2)';
    }
}

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    links:
      - endpoint: https
        host-env: FLASHCARD_BACKEND_HTTPS_HOST
        port-env: FLASHCARD_BACKEND_HTTPS_PORT
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'service', in => 'link',
   'Cannot cope with missing service field in link';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    links:
      - service: flashcard-backend
        host-env: FLASHCARD_BACKEND_HTTPS_HOST
        port-env: FLASHCARD_BACKEND_HTTPS_PORT
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'endpoint', in => 'link',
   'Cannot cope with missing endpoint field in link';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    links:
      - service: flashcard-backend
        endpoint: https
        port-env: FLASHCARD_BACKEND_HTTPS_PORT
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'host-env', in => 'link',
   'Cannot cope with missing host-env field in link';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    links:
      - service: flashcard-backend
        endpoint: https
        host-env: FLASHCARD_BACKEND_HTTPS_HOST
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'port-env', in => 'link',
   'Cannot cope with missing port-env field in link';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    links:
      - service: flashcard-backend
        endpoint: https
        host-env: FLASHCARD_BACKEND_HTTPS_HOST
        port-env: FLASHCARD_BACKEND_HTTPS_PORT
        wat: watermelon
    YAML
    X::Cro::Tools::CroFile::Unexpected, field => 'wat', in => 'link',
   'Unexpected link field is an error';

{
    my $parsed;
    lives-ok { $parsed = Cro::Tools::CroFile.parse: q:to/YAML/ }, 'Environment vars parse';
        cro: 1
        id: flashcard-backend
        entrypoint: service.p6
        env:
          - name: FLASH_DATABASE
            value: test-database.internal:6555
          - name: JWT_SECRET
            value: my-dev-not-so-secret
        YAML
    is $parsed.env.elems, 2, 'Parsed 2 environment variables';
    given $parsed.env[0] {
        is .name, 'FLASH_DATABASE', 'Correct environment name (1)';
        is .value, 'test-database.internal:6555', 'Correct environment name (1)';
    }
    given $parsed.env[1] {
        is .name, 'JWT_SECRET', 'Correct environment name (2)';
        is .value, 'my-dev-not-so-secret', 'Correct environment name (2)';
    }
}

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    env:
      - value: test-database.internal:6555
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'name', in => 'env',
   'Cannot cope with missing name field in env';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    env:
      - name: FLASH_DATABASE
    YAML
    X::Cro::Tools::CroFile::Missing, field => 'value', in => 'env',
   'Cannot cope with missing value field in env';

throws-like { Cro::Tools::CroFile.parse: q:to/YAML/ },
    cro: 1
    id: flashcard-backend
    entrypoint: service.p6
    env:
      - name: FLASH_DATABASE
        value: test-database.internal:6555
        wat: cherry
    YAML
    X::Cro::Tools::CroFile::Unexpected, field => 'wat', in => 'env',
   'Unexpected env field is an error';

{
    my $try-serialize = Cro::Tools::CroFile.new(
        id => 'flashcard-backend',
        name => 'Flashcards Backend',
        entrypoint => 'service.p6',
        endpoints => [
            Cro::Tools::CroFile::Endpoint.new(
                id => 'http',
                name => 'HTTP (Insecure)',
                protocol => 'http',
                host-env => 'FLASHCARD_BACKEND_HTTP_HOST',
                port-env => 'FLASHCARD_BACKEND_HTTP_PORT'
            )
        ],
        links => [
            Cro::Tools::CroFile::Link.new(
                service => 'flashcard-backend',
                endpoint => 'https',
                host-env => 'FLASHCARD_BACKEND_HTTPS_HOST',
                port-env => 'FLASHCARD_BACKEND_HTTPS_PORT'
            )
        ],
        env => [
            Cro::Tools::CroFile::Environment.new(
                name => 'FLASH_DATABASE',
                value => 'test-database.internal:6555'
            )
        ]
    );

    my $yaml;
    lives-ok { $yaml = $try-serialize.to-yaml() }, 'Serializing to YAML lives';
    like $yaml, /'"'? 'cro' '"'? \s* ':' \s* 1/, 'Has cro version identifier';

    my $parsed;
    lives-ok { $parsed = Cro::Tools::CroFile.parse($yaml) }, 'Could parse output';
    is $parsed.id, 'flashcard-backend', 'Correct id (roundtrip)';
    is $parsed.name, 'Flashcards Backend', 'Correct name (roundtrip)';
    is $parsed.entrypoint, 'service.p6', 'Correct entrypoint (roundtrip)';
    is $parsed.endpoints.elems, 1, 'Roundtripped 1 endpoint';
    given $parsed.endpoints[0] {
        is .id, 'http', 'Correct endpoint id (roundtrip)';
        is .name, 'HTTP (Insecure)', 'Correct endpoint name (roundtrip)';
        is .protocol, 'http', 'Correct endpoint protocol (roundtrip)';
        is .host-env, 'FLASHCARD_BACKEND_HTTP_HOST', 'Correct endpoint host-env (roundtrip)';
        is .port-env, 'FLASHCARD_BACKEND_HTTP_PORT', 'Correct endpoint port-env (roundtrip)';
    }
    is $parsed.links.elems, 1, 'Roundtripped 1 link';
    given $parsed.links[0] {
        is .service, 'flashcard-backend', 'Correct link service (roundtrip)';
        is .endpoint, 'https', 'Correct link endpoint (roundtrip)';
        is .host-env, 'FLASHCARD_BACKEND_HTTPS_HOST', 'Correct link host-env (roundtrip)';
        is .port-env, 'FLASHCARD_BACKEND_HTTPS_PORT', 'Correct link port-env (roundtrip)';
    }
    is $parsed.env.elems, 1, 'Roundtripped 1 environment variables';
    given $parsed.env[0] {
        is .name, 'FLASH_DATABASE', 'Correct environment name (roundtrip)';
        is .value, 'test-database.internal:6555', 'Correct environment name (roundtrip)';
    }
}

done-testing;
