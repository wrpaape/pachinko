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
      y_row
      |> pad

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

  def axis_and_stats(n) do
    std_bins =
      n * @p * (1 - @p)
      |> :math.pow(0.5)

    resolution =
      2 * (n + 1)

    resolution_printable =
      resolution
      |> - 11

    std_cols =
      resolution * std_bins / n

    std_max =
      resolution_printable / std_cols
      |> round
      |> div(2)

    {top, bot} =
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
      pad(top_pad_len)
      <> top
      |> cap("┤ ", "\n  ")

    {top_counters_row_offset, bot_counters_row_offset} =
      if n |> Integer.is_odd, do: {1, 3}, else: {3, 1}

    bot =
      "0"
      |> cap(String.reverse(bot), bot)
      |> cap("    ")
      |> cap(pad(top_pad_len + top_counters_row_offset), "\n")

      [std, pr_left, pr_right] =
        [std_bins, 1 - @p, @p]
        |> Enum.map(&Float.to_string(&1, decimals: 2))

    static_stats =
      [
        "df: #{n} layers",
        "σ: #{std} bins",
        "p(←/→): #{pr_left}/#{pr_right}"
      ]

    static_stats_len =
      static_stats
      |> Enum.reduce(0, &(byte_size(&1) + &2))

    static_stats_pad =
      resolution_printable
      |> - static_stats_len
      |> div(2)
      |> pad
  
    static_stats_aligned =
      static_stats
      |> Enum.take(2)
      |> Enum.map(fn(s_stat) ->
        s_stat <> static_stats_pad
      end)
      |> List.insert_at(2, List.last(static_stats))

    static_stats = 
      static_stats_aligned
      |> cap(pad(bot_counters_row_offset), " \n")

    # dynamic_stats_pad =
    #   resolution_printable
    #   |> - 37
    #   |> div(2)
    #   |> pad

    print_dynamic_stats =
    fn
      %{total_count: 0} -> ""
      %{total_count: total_count, chi_squared: chi_squared, p_value: p_value} ->
      total_count_str = 
        total_count
        |> Integer.to_string

      # total_count_print =
      #   4
      #   |> - byte_size(total_count_str)
      #   |> pad
      #   |> cap(" N: ", total_count_str)

      [{"χ²: ", 4, chi_squared}, {"p-value: ", p_value}]
      |> Enum.map(dynamic_stats_pad, fn({token, _token_len, stat}) ->
        token <> Float.to_string(stat, decimals: 6)
      end)
      |> List.insert_at(0, " N: " <> total_count_str)
      |> Enum.zip(static_stats_aligned)
      |> reduce(fn({d_stat, s_stat}, acc) ->
        s_stat
        |> byte_size
        |> pad
      end)

      # |> cap(total_count_print <> dynamic_stats_pad, " ")

      
      
    end


    {top, bot, static_stats, print_dynamic_stats}
  end
  
  defp pad(pad_len), do: String.duplicate(" ", pad_len)
end