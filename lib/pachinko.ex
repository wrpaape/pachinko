defmodule Pachinko do
  use Application

  require Pachinko.Define

  alias Pachinko.Fetch
  alias Pachinko.Define

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    spread_and_pad = Fetch.spread_and_pad!

    if spread_and_pad == :toggle_fullscreen do
      toggle_fullscreen

      Define.stop_callback(&toggle_fullscreen/0)
      
      sleep 1500
      
      spread_and_pad = Fetch.spread_and_pad
    end

    {:ok, _sup_pid} =
      spread_and_pad
      |> Pachinko.Supervisor.start_link
  end

  def reflect_stagger(max), do: -max..max |> Enum.take_every(2)

  def toggle_fullscreen do
    '''
    osascript << "EOF"
      tell application "System Events"
        keystroke "f" using { command down, control down }
      end tell
    EOF
    '''
    |> :os.cmd
  end
end