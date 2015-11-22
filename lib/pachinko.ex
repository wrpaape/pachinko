defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    {:ok, _sup_pid} =
      fetch_spread_and_pad!
      |> Pachinko.Supervisor.start_link
  end

  def reflect_stagger(max), do: -max..max |> Enum.take_every(2)

  defp to_whole_microseconds(seconds_per_frame) do
    seconds_per_frame * 1000
    |> Float.ceil
    |> trunc
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

  # defp fetch_spread_and_pad!(:test), do: {1, 0}
  defp fetch_spread_and_pad! do
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

  def fetch_pr_right! do

  end
end
