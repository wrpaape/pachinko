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
      |> Enum.map(&[&1, self]) #self in place of server_pid
      |> Enum.map(&Pachinko.Printer.init/1)
      |> Enum.map(fn{ :ok, {peg_rows, _server_pid} } ->
        peg_rows
      end)

    assert lhs == rhs
  end

  test "init returns a pid" do
    { :ok, {_peg_rows, server_pid} } =
      [0, self]
      |> Pachinko.Printer.init

    lhs = is_pid(server_pid)
    rhs = true
    
    assert lhs == rhs
  end

  test "state returns {peg_rows, server_pid}" do
    # app initialized with a max_ball_spread of 1 in test environment,
    # so 2 rows of pegs are generated
    {peg_rows, server_pid} = Pachinko.Printer.state

    lhs = { [%{0 => " "}, %{-1 => " ", 1 => " "}],         true       }
    rhs = {                peg_rows              , is_pid(server_pid) }

    assert lhs == rhs
  end
end
