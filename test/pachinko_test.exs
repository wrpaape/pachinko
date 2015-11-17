defmodule Pachinko.Test do
  use ExUnit.Case
  doctest Pachinko

  test "generate_slots returns Keyword by default" do
    rhs = [{-3, " "}, {-1, " "}, {1, " "}, {3, " "}]
    lhs = Pachinko.generate_slots(3, " ")

    assert lhs == rhs
  end

  test "generate_slots returns Map with :into_map option" do
    rhs = %{-3 => " ", -1 => " ", 1 => " ", 3 => " "}
    lhs = Pachinko.generate_slots(3, " ", :into_map)

    assert lhs == rhs
  end
end
