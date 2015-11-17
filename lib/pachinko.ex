defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, spread_and_pad) do
    import Supervisor.Spec, warn: false

    {:ok, _sup_pid} =
      spread_and_pad
      |> Pachinko.Supervisor.start_link
  end

  def reflect_stagger(max), do: Enum.take_every(-max..max, 2)
end
