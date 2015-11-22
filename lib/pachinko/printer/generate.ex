defmodule Pachinko.Printer.Generate do
  alias Pachinko.Fetch
  alias IO.ANSI

  require Integer

  import Pachinko.Printer, only: [cap: 2, cap: 3]

  @p Fetch.pr_shift_right!

  @moduledoc """
  Module responsible for generating initial state for Printer process.
  """

  def counter_pieces(max_ball_spread) do
    mouths =
      max_ball_spread
      |> Pachinko.reflect_stagger

    base =
      "─"
      |> List.duplicate(max_ball_spread + 1)
      |> Enum.join("┴")

    {mouths, ANSI.white <> cap(base, "└", "┘")}
  end

  def peg_row({y_row, num_pegs}, y_overflow) do
    pad =
      " "
      |> String.duplicate(y_row)

    slots =
      num_pegs
      |> Pachinko.reflect_stagger

    y_ratio = y_row / y_overflow

    row_color =
      cond do
        y_ratio > 0.85 -> ANSI.bright <> ANSI.magenta
        y_ratio > 0.70 -> ANSI.bright <> ANSI.red
        y_ratio > 0.55 ->                ANSI.yellow
        y_ratio > 0.40 ->                ANSI.green  
        y_ratio > 0.20 -> ANSI.faint  <> ANSI.cyan
        true           -> ANSI.faint  <> ANSI.blue
      end

    {[pad | slots], y_row, row_color}
  end

  def bell_curve_axis(n) do
    std_bins =
      n * @p * (1 - @p)
      |> :math.pow(0.5)

    resolution =
      2 * (n + 1)

    std_cols =
      resolution * std_bins / n

    std_max =
      (resolution - 11) / std_cols
      |> round
      |> div(2)

    {top, mid} =
      1..std_max
      |> Enum.reduce({"", ""}, fn(x, {top_acc, bot_acc}) ->
        len =
          x * std_cols
          |> round
          |> - 1

        { String.ljust(top_acc, len, ?─) <> "┼", String.ljust(bot_acc, len) <> Integer.to_string(x)}
      end)

    top =
      "┼"
      |> cap(String.reverse(top), top)
      |> cap("σ⁻<─", "─>σ⁺")

    top_pad_len =
      resolution
      |> - String.length(top)
      |> div(2)

    top =
      String.duplicate(" ", top_pad_len)
      <> top
      |> cap("┤ ", "\n  ")

    mid_pad_len =
      if n |> Integer.is_odd, do: 1, else: 3

    mid =
      "0"
      |> cap(String.reverse(mid), mid)
      |> cap("    ")
      |> cap(String.duplicate(" ", top_pad_len + mid_pad_len), "\n")

    bot_segs =
      [
        "n: #{n} layers",
        "σ: #{Float.round(std_bins, 2)} bins",
        "N:"
      ]

    bot_segs_len =
      bot_segs
      |> Enum.reduce(0, &(byte_size(&1) + &2))

    bot_segs_pad_len =
      resolution
      |> - 11
      |> - bot_segs_len
      |> div(2)
  
    bot =
      bot_segs
      |> Enum.join(String.duplicate(" ", bot_segs_pad_len))
      |> cap(" ")

    {top, mid, bot}
  end
  
end