defmodule PachinkoTest do
  @max_ball_spreads [0, 1, 2, 3, 4]

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
      @max_ball_spreads
      |> Enum.map(&Pachinko.Server.init/1)

    assert lhs == rhs
  end

  test "state does not return dead balls" do
    Pachinko.Server.state
  end

  test "update puts balls in play at first, no buckets are updated" do
    {:ok, _server_pid} = Pachinko.Server.start_link(10)
    {:reply, {live0, buckets0}} = Pachinko.Server.state
    {:reply, {live0, buckets0}} = Pachinko.Server.update
  end

  # helper functions

  defp map_map_apply(funs, args), do: Enum.map(args, &map_apply(funs, &1))

  defp map_apply(funs),                            do: map_apply(funs, [])
  defp map_apply(funs, arg) when not is_list(arg), do: map_apply(funs, [arg])
  defp map_apply(funs, args),                      do: Enum.map(funs, &apply(&1, args))
end
