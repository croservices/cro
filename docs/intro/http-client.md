# Making HTTP requests

The Cro HTTP client makes it easy to make simple requests, while having a
powerful range of features for more complex situations.

The simplest `GET` request can be written as:

```
# Import the client class.
use Cro::HTTP::Client;

# Make the request
my $resp = await Cro::HTTP::Client.get('https://www.perl6.org/');
```

Different methods represent different HTTP methods, such as `get`,
`post`, `put` and `delete`. Every such method returns a `Promise` that
will be kept when the response is returned. This `Promise` is kept with
a `Cro::HTTP::Response` instance. The body of the request is also provided
using a `Promise`, since it may arrive later than the initial response
header.

```
my $body = await $resp.body;
```

To keep the defaults for every request, one can create an instance of
the client and specify them at construction time. For example, the user
agent header could be set on every request as follows:

```
my $client = Cro::HTTP::Client.new(
    headers => [
        User-agent => 'Cro'
    ]);
my $resp = await $client.get('https://www.perl6.org/');
```

Making an instance has the advantage that connections will be re-used between
requests, or in the case of HTTP/2.0 they will be multiplexed onto a single
connection.

For more details, see the complete `Cro::HTTP::Client` documentation.
