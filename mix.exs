defmodule Popplex.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :popplex,
      version: @version,
      name: "Popplex",
      description: "Elixir wrapper for PDF tools using Poppler",
      source_url: "https://github.com/mylanconnolly/popplex",
      homepage_url: "https://github.com/mylanconnolly/popplex",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_targets: ["all"],
      make_clean: ["clean"],
      package: package(),
      docs: docs()
    ]
  end

  defp docs do
    [
      main: "Popplex",
      extras: ["README.md", ".github/CONTRIBUTING.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        "Core API": [Popplex],
        "Native Interface": [Typster.NIF]
      ]
    ]
  end

  defp package do
    [
      name: "popplex",
      files: ~w(lib c_src .formatter.exs mix.exs CHANGELOG.md README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mylanconnolly/typster"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.8", runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
