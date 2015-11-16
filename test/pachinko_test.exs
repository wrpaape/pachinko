defmodule PachinkoTest do
  use ExUnit.Case
  doctest Pachinko

  test "generate_slots returns proper map" do
    rhs = %{-3 => " ", -1 => " ", 1 => " ", 3 => " "}
    lhs = Pachinko.generate_slots(3, " ")

    assert lhs == rhs
  end

  test "intializing server returns proper state" do
    eb = {0,0,0} # empty bucket
    lhs = 
    [
      { :ok, { [0], [], %{0 => eb} } },
      { :ok, { [0, 0], [], %{-1 => eb, 1 => eb} } },
      { :ok, { [0, 0, 0], [], %{-2 => eb, 0 => eb, 2 => eb} } },
      { :ok, { [0, 0, 0, 0], [], %{-3 => eb, -1 => eb, 1 => eb, 3 => eb} } },
      { :ok, { [0, 0, 0, 0, 0], [], %{-4 => eb, -2 => eb, 0 => eb, 2 => eb, 4 => eb} } }
    ]
    rhs =
      0..4
      |> Enum.map(&Pachinko.Server.init/1)

    assert lhs == rhs
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
    # so at most 2 balls in play
    {[],     buckets0} = Pachinko.Server.state
    {[0],    buckets1} = Pachinko.Server.update
    {[0, _], buckets2} = Pachinko.Server.update
    {[0, _], buckets3} = Pachinko.Server.update

    lhs = {buckets0 == buckets1, buckets1 == buckets2, buckets2 == buckets3}
    rhs = {        true        ,         true        ,         false       }
    
    assert lhs == rhs
  end

  # helper functions

  # defp map_map_apply(funs, args), do: Enum.map(args, &map_apply(funs, &1))

  # defp map_apply(funs),                            do: map_apply(funs, [])
  # defp map_apply(funs, arg) when not is_list(arg), do: map_apply(funs, [arg])
  # defp map_apply(funs, args),                      do: Enum.map(funs, &apply(&1, args))
end
