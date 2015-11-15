defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Pachinko.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pachinko.Supervisor]
    Supervisor.start_link(children, opts)
  end


  defp peg_row(num_pegs) do
    -num_pegs..num_pegs
    |> Enum.take_every(2)
    |> Enum.map(&{&1, " "})
    |> Enum.into(%{})
  end

  defp splice_ball(peg_row, ball_pos) do
    peg_row
    |> Map.put(ball_pos, "●")
    |> Map.values
    |> Enum.join(".")
  end
end
