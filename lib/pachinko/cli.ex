defmodule Pachinko.CLI do
  @default_frame_rate 30

  @moduledoc """
  Handle the command line parsing and the dispatch to the various
  functions that end up generating a table of the last _n_ issues
  in a github project.
  """

  def run(argv) do
    parse_args(argv)
  end

  @doc """
  `argv` can be -h or --help, which returns :help.
  Otherwise it is a github user name, project name, and
  (optionally) the number of entries to format. Return a tuple of
  `{ user, project, count }`, or `:help` if help was given.
  """
  def parse_args(argv) do
    opts =
      [
        strict:
          [
            help:       :boolean,
            frame_rate: :integer
          ],
        aliases:
        [
          h:   :help,
          f:   :frame_rate,
          fr:  :frame_rate,
          fps: :frame_rate
        ]
      ]

    {parsed, _argv, errors} =
    argv
    |> OptionParser.parse(opts)
    end
  end
end