# AbsintheRateLimiting

[![Hex.pm](https://img.shields.io/hexpm/v/absinthe_rate_limiting.svg)](https://hex.pm/packages/absinthe_rate_limiting)

<!-- README START -->

`absinthe_rate_limiting` is a middleware-based rate limiter for
[Absinthe](https://hexdocs.pm/absinthe/overview.html) that uses
[Hammer](https://hexdocs.pm/hammer/index.html).

## Installation

`absinthe_rate_limiting` is [available in
Hex](https://hexdocs.pm/absinthe_rate_limiting), and can be installed by adding
`:absinthe_rate_limiting` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:absinthe_rate_limiting, "~> 0.1.0"}
  ]
end
```

## Basic usage

To use the rate limiting middleware, you must first configure Hammer. See the
[Hammer documentation](https://hexdocs.pm/hammer) for more information.

The next step is to add the middleware to the query that needs to be rate
limited:

```elixir
field :my_field, :string do
  middleware AbsintheRateLimiting.RateLimit
  resolve &MyApp.Resolvers.my_field/3
end
```

For the full usage information, see `AbsintheRateLimiting.RateLimit`.

<!-- README END -->
