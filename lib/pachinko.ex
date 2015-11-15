defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    def start(_type, _args) do
    :sequence
    |> Application.get_env(:initial_number)
    |> Sequence.Supervisor.start_link
  end

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Pachinko.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pachinko.Supervisor]
    Supervisor.start_link(children, opts)
  end


  defp splice_ball(peg_row, ball_pos) do
    peg_row
    |> Map.put(ball_pos, "●")
    |> Map.values
    |> Enum.join(".")
  end

  def generate_slots(max_pos, token) do
    -max_pos..max_pos
    |> Enum.take_every(2)
    |> Enum.map(&{&1, token})
    |> Enum.into(%{})
  end
end
