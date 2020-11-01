defmodule TeslaCacher.MixProject do
  use Mix.Project

  @version "0.2.0"
  @description "A Basic Cache Middleware for Tesla backed by Redis."
  @repo_url "https://github.com/OldhamMade/TeslaCacher"

  def project do
    [
      app: :tesla_cacher,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      package: package(),
      description: @description,

      # Docs
      name: "TeslaCacher",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      maintainers: ["Phillip Oldham"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @repo_url},
      files: ~w(lib .formatter.exs mix.exs *.md LICENSE)
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.3"},
      {:redix, "~> 1.0"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
    ]
  end

  defp docs() do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @repo_url,
      extras: [
        "README.md",
      ]
    ]
  end
end
