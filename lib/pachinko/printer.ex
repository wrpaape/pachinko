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

slots = num_pegs |> Pachinko.generate_slots(" ")
slots |>  Map.put(ball_pos, "●") |> Map.values |> Enum.join(".")

  """

# {:next_state, [0, -1, -2, 1, 0, -3, 4, -1, -2, 3, -2],
#  %{-10 => 0, -8 => 7, -6 => 54, -4 => 150, -2 => 237, 0 => 288, 2 => 245,
#    4 => 116, 6 => 58, 8 => 13, 10 => 0}}

  def start do
    {:ok, cols} = :io.columns
    max_pos = div(cols + 1, 2)
    server = spawn()

    |> generate_peg_rows
    |> ready
  end

  def generate_peg_rows(last_num_pegs) do
    0..last_num_pegs
    |> Enum.map(fn(num_pegs) ->
      num_pegs |> Pachinko.generate_slots(" ")
    end)
  end

  def ready(peg_rows) do
    rec

  end

  def print_curve(distribution) do
    
    {full_blocks, remaining}

    {:ok, rows} = :io.rows
    rows..1
    |> Enum.map_join("\n", fn(row) ->
      distribution
      |> Enum.map_join(fn(bucket_count) ->
        row * 8 - bucket_count
      end)
    end)

  end

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