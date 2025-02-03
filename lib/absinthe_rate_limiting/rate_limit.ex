defmodule AbsintheRateLimiting.RateLimit do
  @moduledoc """
  Rate limiting middleware for Absinthe.

  ## Usage

  To use the rate limiting middleware, you must first configure Hammer. See the
  [Hammer documentation](https://hexdocs.pm/hammer) for more information.

  The next step is to add the middleware to the query that needs to be rate
  limited:

      field :my_field, :string do
        middleware AbsintheRateLimiting.RateLimit
        resolve &MyApp.Resolvers.my_field/3
      end

  ## Configuration
  The available configuration options are:

  | Option       | Description                                                                                                                                                                                                                                                     | Default Value                  |
  |--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|
  | `:scale_ms`  | Integer indicating size of bucket in milliseconds.                                                                                                                                                                                                              | `60_000`                       |
  | `:limit`     | Integer maximum count of actions within the bucket. In other words, the maximum number of requests that are allowed in `:scale_ms` milliseconds.                                                                                                                | `25`                           |
  | `:result`    | The result to return when the rate limit is exceeded.                                                                                                                                                                                                           | `{:error, :too_many_requests}` |
  | `:id`        | The name of the bucket, or a list of keys to fetch the name from the context or arguments. The bucket will always be scoped per field.                                                                                                                          | `"default"`                    |
  | `:id_source` | The source of the ID, either `:static`, `:context`, or `:arguments`. When the source is `:static`, `:id` will be used as the name of the bucket. Otherwise, the Absinthe context or the arguments passed to the field respectively will be indexed using `:id`. | `:static`                      |

  The default values can be configured in your `config.exs`:

      config :absinthe_rate_limiting,
        scale_ms: 60_000,
        limit: 25,
        result: {:error, :too_many_requests},
        id: "default",
        id_source: :static

  These values can be overridden for each field in the schema definition by
  passing them as options to the middleware:

      field :my_field, :string do
        middleware AbsintheRateLimiting.RateLimit, limit: 10
        resolve &MyApp.Resolvers.my_field/3
      end

  ## Disabling rate limiting

  Rate limiting can be disabled by setting the `:active` configuration option to `false` in your `config.exs`:

      config :absinthe_rate_limiting,
        active: false
  """

  @behaviour Absinthe.Middleware

  @impl true
  def call(resolution = %Absinthe.Resolution{state: :resolved}, _config),
    do: resolution

  @impl true
  def call(resolution, config) do
    if Application.get_env(:absinthe_rate_limiting, :active, true) do
      check_rate_limit(resolution, config)
    else
      resolution
    end
  end

  defp check_rate_limit(resolution, config) do
    scale_ms = Keyword.get_lazy(config, :scale_ms, &get_default_scale_ms/0)
    limit = Keyword.get_lazy(config, :limit, &get_default_limit/0)
    result = Keyword.get_lazy(config, :result, &get_default_result/0)

    id = Keyword.get_lazy(config, :id, &get_default_id/0)
    id_source = Keyword.get_lazy(config, :id_source, &get_default_source/0)

    id = get_id(resolution, id, id_source)
    id = "absinthe:#{resolution.definition.name}:#{id}"

    case Hammer.check_rate(id, scale_ms, limit) do
      {:allow, _} -> resolution
      {:deny, _} -> Absinthe.Resolution.put_result(resolution, result)
    end
  end

  defp get_id(_resolution, id, :static), do: id

  defp get_id(%Absinthe.Resolution{context: context}, id, :context) do
    get_in(context, List.wrap(id)) || raise "ID not found in context"
  end

  defp get_id(%Absinthe.Resolution{arguments: arguments}, id, :arguments) do
    get_in(arguments, List.wrap(id)) || raise "ID not found in arguments"
  end

  defp get_default_id do
    Application.get_env(:absinthe_rate_limiting, :default_id, "default")
  end

  defp get_default_source do
    Application.get_env(:absinthe_rate_limiting, :default_source, :static)
  end

  defp get_default_scale_ms do
    Application.get_env(:absinthe_rate_limiting, :default_scale_ms, 60 * 1000)
  end

  defp get_default_limit do
    Application.get_env(:absinthe_rate_limiting, :default_limit, 25)
  end

  defp get_default_result do
    Application.get_env(:absinthe_rate_limiting, :default_result, {:error, :too_many_requests})
  end
end
