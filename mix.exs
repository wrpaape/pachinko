defmodule Pachinko.Mixfile do
  use Mix.Project

  def project do
    [app: :pachinko,
     version: "0.0.1",
     elixir: "~> 1.1",
     escript: escript_config,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger],
      mod: {Pachinko, fetch_args!},
      registered: [Pachinko.Server, Pachinko.Printer]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    []
  end

  defp fetch!({:ok, result}), do: result
  defp fetch_dims! do
    [:rows, :columns]
    |> Enum.map(fn(dim) ->
      :io
      |> apply(dim, [])
      |> fetch!
    end)
  end

  defp fetch_spread_and_pad!(:test), do: {1, 0}
  defp fetch_spread_and_pad!(_env) do
    [rows, columns] = fetch_dims!
    
    max_height =
      rows
      |> - 6

    max_ball_spread = 
      columns
      |> - 1
      |> div(2)
      |> - 2
      |> div(2)
      |> min(max_height)

    top_pad_len =
      max_height
      |> - max_ball_spread

    { max_ball_spread, String.duplicate("\n", top_pad_len) }
  end

  defp fetch_args! do
    Mix.env
    |> fetch_spread_and_pad!
    |> List.wrap
    |> Enum.concat(fetch_frame_interval! |> List.wrap)
  end

  defp escript_config do
    [
      main_module: Pachinko.CLI
    ]
  end
end
