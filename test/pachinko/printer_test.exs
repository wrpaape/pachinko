defmodule Pachinko.Printer.Test do
  use ExUnit.Case
  doctest Pachinko.Printer

  test "init returns proper peg_rows" do
    lhs = 
    [
      [
        %{ 0 => " "}
      ],
      [
        %{ 0 => " "},
        %{-1 => " ", 1 => " "}
      ],
      [
        %{ 0 => " "},
        %{-1 => " ", 1 => " "},
        %{-2 => " ", 0 => " ", 2 => " "}
      ]
    ]
    rhs =
      0..2
      |> Enum.map(&Pachinko.Printer.init/1)
      |> Enum.map(fn{:ok, peg_rows, _pids} ->
        peg_rows
      end)

    assert lhs == rhs
  end

  test "init returns proper state" do


    assert true
  end

  test "state returns {live_balls, buckets}, never dead balls" do
    lhs =
      Pachinko.Server.state
      |> tuple_size
    rhs = 2

    assert lhs == rhs
  end

  test "buckets are not updated until after all balls are in play" do
    # app initialized with a max_ball_spread of 1 in test environment,
    # so 2 rows of pegs are generated
    {[],     buckets0} = Pachinko.Server.state
    {[0],    buckets1} = Pachinko.Server.update
    {[0, _], buckets2} = Pachinko.Server.update
    {[0, _], buckets3} = Pachinko.Server.update

    lhs = {buckets0 == buckets1, buckets1 == buckets2, buckets2 == buckets3}
    rhs = {        true        ,         true        ,         false       }
    
    assert lhs == rhs
  end
end
