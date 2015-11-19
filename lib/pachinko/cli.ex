defmodule Pachinko.CLI do
  @moduledoc """
  Handle the command line parsing and the dispatch to the various
  functions that end up generating a table of the last _n_ issues
  in a github project.
  """

  def run(argv) do
    parse_args(argv)
  end

  def main do
    frame_interval
    |> Pachinko.Printer.start
  end
end