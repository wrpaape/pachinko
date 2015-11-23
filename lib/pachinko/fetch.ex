defmodule Pachinko.Fetch do
  @moduledoc """
  Module responsible for fetching configuration values
  """

  ########################################################################
  #                             external API                             #
  ########################################################################

  def frame_intervals! do
    frame_interval =
      :frame_rate
      |> get_env
      |> :math.pow(-1) 
      |> to_whole_microseconds

    {frame_interval, Integer.to_string(frame_interval * 1000)}
  end

  # def spread_and_pad!(:test), do: {1, 0}
  def spread_and_pad! do
    [rows, columns] =
      [:rows, :columns]
      |> Enum.map(&dim!/1)

    max_height =
      rows
      |> - 7

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

  def pr_shift_right! do
    :pr_shift_right
    |> get_env
  end
  

  def dim!(dim), do: apply(:io, dim, []) |> fetch!

  ######################################################################
  #                          private helpers                           #
  ######################################################################
  
  defp fetch!({:ok, result}), do: result

  defp get_env(config_key) do
    :pachinko
    |> Application.get_env(config_key)
  end

  defp to_whole_microseconds(seconds_per_frame) do
    seconds_per_frame * 1000
    |> Float.ceil
    |> trunc
  end
end