defmodule Pachinko.Printer do
  @moduledoc """
  Prints Pachinko state to stdio.
  """
  """
  ◬│●
  ▁▂▃▄▅▆▇█
           ●

[, ,.]
slots [ , , , ]
. . . . .
. . . . .
     ●    
    ●.       1|4  ball_pos: -1 , pegs: [0]            slots = %{-1: " ", 1: " "}
    .●.      2|3  ball_pos:  0 , pegs: [-1, 1]        slots = %{-2: " ", 0: " ", 2: " "}
   . .●.     3|2  ball_pos:  1 , pegs: [-2, 0, 2]     slots = %{-3: " ", -1: " ", 1: " ", 3: " "}
  . . . .●   4|1  ball_pos:  4 , pegs: [-3, -1, 1, 3]  
├ ┼ ┼●┼ ┼ ┤  cols = 11 / 12
│0│0│0│0│0│   
└─┴─┴─┴─┴─┘

cols        = Fetch.dim(:cols)
num_buckets = cols / 2 |> Float.ceil |> trunc
num_rows    = num_buckets - 1
ball_pos  = 
len_lpad    = num_rows - row + 1

slots = -num_pegs..num_pegs |> Enum.take_every(2) |> Enum.map(&{&1, " "}) |> Enum.into(%{})
slots |>  Map.put(ball_pos, "●") |> Map.values |> Enum.join(".")

  """

  # defp new(num_pegs) do
  #   -num_pegs..num_pegs
  #   |> Enum.take_every(2)
  #   |> Enum.map(&{&1, " "})
  #   |> Enum.into(%{})
  # end

  # defp splice_ball(peg_row, ball_pos) do
  #   peg_row
  #   |> Map.put(ball_pos, "●")
  #   |> Map.values
  #   |> Enum.join(".")
  # end



  # defp blocks, do: 9601..9608 |> Enum.to_list |> to_string

  # defp pad(len), do: String.duplicate(" ", len)
  # defp pegs(num_pegs), do: String.duplicate(" .", num_pegs)
  # defp blank_row(len, row), do: pad(len) <> pegs(row)
  # defp blank_body(num_rows) do
  #   1..num_rows
  #   |> Enum.map_join("\n", &blank_row(num_rows - &1 + 1, &1))
  # end

  # # defp crosses(num_crosses), do: String.duplicate(" ┼", num_crosses)
  # defp heads(num_buckets), do: "├" <> crosses(num_buckets) <> " ┤"
  # # defp counters(counts), do: 
  # defp blank_buckets(num_buckets), do:

  #   heads(num_buckets) <> counters(num_buckets) <> bases(num_buckets)
  # end

  # def test do
  #   # rows = Fetch.dim(:rows)
  #   cols        = Fetch.dim(:cols)
  #   num_buckets = cols / 2 |> Float.ceil |> trunc
  #   num_rows    = num_buckets - 1
    
  #   body = num_rows |> blank_body
  #   buckets = num_buckets |> blank_buckets
  # end
end