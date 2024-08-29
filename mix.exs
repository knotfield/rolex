defmodule Rolex.MixProject do
  use Mix.Project

  @source_url "https://github.com/knotfield/rolex"
  @version "0.1.0"

  def project do
    [
      app: :rolex,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Hex
      description: "A role management library for Elixir apps",
      package: package(),

      # Docs
      name: "Rolex",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: mod(Mix.env()),
      extra_applications: [:logger]
    ]
  end

  defp mod(env) when env in [:dev, :test], do: {Rolex.Application, []}
  defp mod(_), do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:ex_unit_notifier, "~> 1.2", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:postgrex, ">= 0.0.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp aliases do
    [
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.watch.focus": ["test.watch --exclude test --include focus"],
      dot: ["xref graph --format dot --output -"]
    ]
  end
end
