defmodule Pachink.PegRow do
  @moduledoc """
  Module from which
  """

  defp new(num_pegs) do
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

  # @doc """
  # Receives ball_pos and splices a ball token (●)
  # into a row of peg tokens (.) accordingly:

  # {:ball, -2} => "●. . "
  # {:ball,  1} => " . . .●. . "

  # before dispatching the resulting display string
  # to the printer.
  # """
  # defp wait_for_ball(peg_row) do
  #   receive do
  #     {:ball, ball_pos} ->
  #       display = 
  #         peg_row
  #         |> Map.put(ball_pos, "●")
  #         |> Map.values
  #         |> Enum.join(".")
  #       send(Pachinko.Printer, :print_row, [{self, display}])
  #       wait_for_ball(peg_row)
  #   end
  # end
end