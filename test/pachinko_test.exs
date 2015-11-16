defmodule PachinkoTest do
  @max_ball_spreads [0, 10, 50]

  use ExUnit.Case
  doctest Pachinko

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "generate_slots returns proper map" do
    rhs = %{-3 => " ", -1 => " ", 1 => " ", 3 => " "}
    lhs = Pachinko.generate_slots(3, " ")

    assert lhs == rhs
  end

  # test "intializing server returns proper state" do
    

  #   [lhs, rhs] =
  #     [  
  #       &Pachinko.Server.generate_balls/1,
  #       &List.duplicate(0, &1)
  #     ] |> apply_each(max_ball_spread)

  #   assert lhs == rhs
  # end

  # helper functions
  defp map_map_apply(funs, args), do: Enum.map(args, &map_apply(funs, &1))

  defp map_apply(funs),                            do: map_apply(funs, [])
  defp map_apply(funs, arg) when not is_list(arg), do: map_apply(funs, [arg])
  defp map_apply(funs, args),                      do: Enum.map(funs, &apply(&1, args))
end
