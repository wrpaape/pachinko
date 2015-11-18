defmodule Pachinko.Mixfile do
  use Mix.Project

  def project do
    [app: :pachinko,
     version: "0.0.1",
     elixir: "~> 1.1",
     # escript: escript_config,
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
    
    max_ball_spread = 
      columns
      |> div(2)
      |> + 1
      |> div(2)
      |> - 3

    top_pad_len =
      rows
      |> - max_ball_spread
      |> - 3

    { max_ball_spread, String.duplicate("\n", top_pad_len) }
  end
  
  defp to_whole_microseconds(seconds_per_frame) do
    seconds_per_frame * 1000
    |> Float.ceil
    |> trunc
  end
  
  defp fetch_frame_interval! do
    :pachinko
    |> Application.get_env(:frame_rate)
    |> :math.pow(-1) 
    |> to_whole_microseconds
  end

  defp fetch_args! do
    Mix.env
    |> fetch_spread_and_pad!
    |> List.wrap
    |> Enum.concat(fetch_frame_interval! |> List.wrap)
  end
end
