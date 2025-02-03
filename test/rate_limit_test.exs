defmodule AbsintheRateLimiting.RateLimitTest do
  use ExUnit.Case, async: false

  import Mock

  defmodule Schema do
    use Absinthe.Schema

    input_object :input_obj do
      field :id, :string
    end

    query do
      field :default_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :scale_ms_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit, scale_ms: 120_000
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :limit_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit, limit: 5
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :static_id_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit, id: "static_id"
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :context_id_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit, id: :id, id_source: :context
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :nested_context_id_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit, id: [:map, :id], id_source: :context
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :arguments_id_configuration, :string do
        arg :id, :string

        middleware AbsintheRateLimiting.RateLimit, id: :id, id_source: :arguments
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :nested_arguments_id_configuration, :string do
        arg :input, :input_obj

        middleware AbsintheRateLimiting.RateLimit, id: [:input, :id], id_source: :arguments
        resolve fn _, _ -> {:ok, "ok"} end
      end

      field :result_configuration, :string do
        middleware AbsintheRateLimiting.RateLimit, result: {:error, :rate_limited}
        resolve fn _, _ -> {:ok, "ok"} end
      end
    end
  end

  @context [context: %{id: "hello_world", map: %{id: "nested_id"}}]

  setup_with_mocks([{Hammer, [], [check_rate: fn _a, _b, _c -> {:allow, 1} end]}]) do
    :ok
  end

  test "works with default configuration" do
    {:ok, _} = Absinthe.run(query(:default_configuration), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:default_configuration:default", 60_000, 25)
  end

  test "accepts override of :scale_ms" do
    {:ok, _} = Absinthe.run(query(:scale_ms_configuration), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:scale_ms_configuration:default", 120_000, 25)
  end

  test "accepts override of :limit" do
    {:ok, _} = Absinthe.run(query(:limit_configuration), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:limit_configuration:default", 60_000, 5)
  end

  test "accepts override of :id (:static)" do
    {:ok, _} = Absinthe.run(query(:static_id_configuration), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:static_id_configuration:static_id", 60_000, 25)
  end

  test "accepts override of :id (:context)" do
    {:ok, _} = Absinthe.run(query(:context_id_configuration), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:context_id_configuration:hello_world", 60_000, 25)
  end

  test "accepts override of :id (:context, nested)" do
    {:ok, _} = Absinthe.run(query(:nested_context_id_configuration), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:nested_context_id_configuration:nested_id", 60_000, 25)
  end

  test "accepts override of :id (:arguments)" do
    {:ok, _} = Absinthe.run(query(:arguments_id_configuration, :id, "hello_world"), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:arguments_id_configuration:hello_world", 60_000, 25)
  end

  test "accepts override of :id (:arguments, nested)" do
    {:ok, _} = Absinthe.run(query(:nested_arguments_id_configuration, :input, %{id: "nested_id"}), __MODULE__.Schema, @context)
    assert_called Hammer.check_rate("absinthe:nested_arguments_id_configuration:nested_id", 60_000, 25)
  end

  test "accepts error msg configuration" do
    with_mock Hammer, [check_rate: fn _a, _b, _c -> {:deny, 1} end] do
      assert {:ok, %{errors: errors}} = Absinthe.run(query(:result_configuration), __MODULE__.Schema, @context)
      assert [
        %{
          locations: [%{column: 3, line: 1}],
          message: "rate_limited",
          path: ["result_configuration"]
        }
      ] == errors
    end
  end

  test "does not apply when resolution is already resolved" do
    resolution = %Absinthe.Resolution{state: :resolved}
    assert resolution == AbsintheRateLimiting.RateLimit.call(resolution, [])
  end

  # Copied from by https://github.com/jungsoft/rajska/blob/master/test/middlewares/rate_limiter_test.exs (MIT)
  defp query(name), do: "{ #{name} }"
  defp query(name, key, value) when is_binary(value), do: "{ #{name}(#{key}: \"#{value}\") }"
  defp query(name, key, %{} = value), do: "{ #{name}(#{key}: {#{build_arguments(value)}}) }"

  defp build_arguments(arguments) do
    arguments
    |> Enum.map(fn {k, v} -> if is_nil(v), do: nil, else: "#{k}: #{inspect(v, [charlists: :as_lists])}" end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
  end
end
