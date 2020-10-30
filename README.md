# TeslaCacher

[![Build Status](https://travis-ci.org/OldhamMade/TeslaCacher.svg?branch=main)][travis]

TeslaCacher is a Basic Cache Middleware for Tesla backed by
[Redix][Redix]. It will cache `GET` requests for `N` milliseconds, if
defined, otherwise for the lifetime of the Redis session. Requests
other than `GET` are **NOT** cached.

Not to be confused with [TeslaCache][Teslacache], which is backed by
[Cachex][Cachex].

## Installation

The package can be installed by adding `tesla_cacher` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tesla_cacher, "~> 0.1.0"}
  ]
end
```

## Usage:

TeslaCacher does not manage Redix for you, you must start and monitor
it yourself and provide the details to the plugin:

```elixir
defmodule MyClient do
  use Tesla

  plug Tesla.Middleware.Cacher,
    redix: :redix,
    expiry: :timer.seconds(2),
    timeout: :timer.seconds(5),
    prefix: :tesla_cacher
end
```

### Options:

`redix` -- [required] the connection handle for redix. Can be an
atom or a PID.

`expiry` -- [optional] (integer or `:infinity`) the expire time, in
milliseconds. Default is `:infinity`.

`timeout` -- [optional] (integer or `:infinity`) request timeout, in
milliseconds. Default is `5000`.

`prefix` -- [optional] (atom or string) a prefix to be used for redis
keys. `|` (pipe) is used as a separator to avoid lookup conflicts with
common redis key schemes. Default is `tesla_cacher`.



[Redix]: https://hex.pm/packages/redix
[Teslacache]: https://hex.pm/packages/tesla_cache
[Cachex]: https://hex.pm/packages/cachex
[travis]: https://travis-ci.org/OldhamMade/TeslaCacher
