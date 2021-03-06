defmodule Pachinko do
  @min_rows 37
  @min_columns 101

  use Application

  alias Pachinko.Fetch

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    if small_screen? do 
      IO.puts "not enough space, resizing to full_screen..."

      toggle_full_screen

      :timer.sleep 1500
    end
      
    {:ok, _sup_pid} =
      Fetch.spread_and_pad!
      |> Pachinko.Supervisor.start_link
  end

  def reflect_stagger(max), do: -max..max |> Enum.take_every(2)

  defp small_screen?, do: Fetch.dim!(:rows) < @min_rows or Fetch.dim!(:columns) < @min_columns

  defp toggle_full_screen do
    '''
    osascript << _OSACLOSE_
      tell application "System Events"
        keystroke "f" using { command down, control down }
      end tell
    _OSACLOSE_
    '''
    |> :os.cmd
  end
end