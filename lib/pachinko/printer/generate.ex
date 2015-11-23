defmodule Pachinko.Printer.Generate do
  alias Pachinko.Fetch
  alias IO.ANSI

  require Integer

  import Pachinko.Printer, only: [cap: 2, cap: 3, pad: 1]

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

    std_cols =
      resolution * std_bins / n

    std_max =
      (resolution - 11) / std_cols
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

    top_len =
      top
      |> String.length

    top_pad_len =
      resolution
      |> - top_len
      |> div(2)

    top_pad =
      top_pad_len
      |> pad

    top =
      top_pad
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
      |> Enum.reduce(0, &(String.length(&1) + &2))

    static_stats_pad_len =
      top_len
      |> - static_stats_len
      |> div(2)
  
    static_stats_no_offset = 
      static_stats
      |> Enum.join(pad(static_stats_pad_len))

    dynamic_stats_pad_lens = 
      static_stats_no_offset
      |> String.split(~r{: }, trim: :true)
      |> Enum.drop(1)
      |> Enum.zip([7, 1])
      |> Enum.map(fn({s_stat, next_token_len}) ->
        s_stat
        |> String.length
        |> - next_token_len
      end)

    static_stats =
      static_stats_no_offset
      |> cap(pad(bot_counters_row_offset + top_pad_len), " \n")

    chi_squared_token = 
      top_pad
      <> " χ²: "

    print_dynamic_stats =
    fn
      %{total_count: 0} -> ""
      %{total_count: total_count, chi_squared: chi_squared, p_value: p_value} ->

      chi_and_p = 
        [{chi_squared_token, chi_squared}, {"p-value: ", p_value}]
        |> Enum.map(fn({token, stat}) ->
          {token, Float.to_string(stat, decimals: 6)}
        end)
        |> Enum.zip(dynamic_stats_pad_lens)
        |> Enum.reduce("", fn({{token, string}, pad_len}, acc) ->
          dyn_pad = 
            pad_len
            |> - byte_size(string)
            |> pad

          acc <> token <> string <> dyn_pad
        end)
      
      "N: "
      |> cap(chi_and_p, Integer.to_string(total_count))
    end


    {top, bot, static_stats, print_dynamic_stats}
  end
end