defmodule Pachinko.Test do
  use ExUnit.Case
  doctest Pachinko

  test "generate_slots returns proper map" do
    rhs = %{-3 => " ", -1 => " ", 1 => " ", 3 => " "}
    lhs = Pachinko.generate_slots(3, " ")

    assert lhs == rhs
  end
end
