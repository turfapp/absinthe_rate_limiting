defmodule AbsintheRateLimiting.MixProject do
  use Mix.Project

  @source_url "https://github.com/turfapp/absinthe_rate_limiting"
  @version "0.1.0"

  def project do
    [
      app: :absinthe_rate_limiting,
      version: @version,
      elixir: "~> 1.14",
      elixirc_path: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      source_url: @source_url,
      deps: deps(),
      docs: [
        main: "AbsintheRateLimiting",
        extras: ["README.md"]
      ]
    ]
  end

  defp package do
    [
      description: "Middleware-based rate limiting for Absinthe",
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        ".formatter.exs"
      ],
      maintainers: [
        "Marijn van Wezel"
      ],
      licenses: ["MIT"],
      links: %{
        Changelog: "#{@source_url}/blob/main/CHANGELOG.md",
        GitHub: @source_url
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.4"},
      {:hammer, "~> 6.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
