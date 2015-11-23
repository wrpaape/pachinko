defmodule Pachinko do
  use Application

  require Pachinko.Define

  alias Pachinko.Fetch
  alias Pachinko.Define

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  # Define.stop_callback(&toggle_fullscreen/0)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # open_new_fullscreen_window

    # :timer.sleep 1500
      
    {:ok, _sup_pid} =
      Fetch.spread_and_pad!
      |> Pachinko.Supervisor.start_link
  end
  
  def main(argv) do
    IO.inspect argv

    Application.stop(:pachinko)

    Fetch.frame_interval!
    |> print_frame
  end

  def stop(:pachinko) do
    # '''
    # osascript << _OSACLOSE_
    #   tell application "Terminal"
    #       close (every window whose name contains "Pachinko")
    #   end tell
    # _OSACLOSE_
    # '''
    # |> :os.cmd
  end

  def reflect_stagger(max), do: -max..max |> Enum.take_every(2)


  def open_new_fullscreen_window do
'''
osascript << _OSACLOSE_
  tell application "Terminal"  
    do script " "  
    activate  
  end tell
  tell application "System Events"
    keystroke "f" using { command down, control down }
  end tell
_OSACLOSE_
'''
|> :os.cmd

Process.group_leader
  end
end