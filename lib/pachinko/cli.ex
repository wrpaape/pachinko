defmodule Pachinko.CLI do
  @max_frame_rate     fetch_config!(:max_frame_rate)
  @default_frame_rate fetch_config!(:default_frame_rate)
  @parse_opts
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
    = 

    # {parsed, raw, errors} =

    config = 
      argv
      |> OptionParser.parse(@parse_opts)
      |> process_invalid_input
      |> handle_errors


    end
  end


  defp prepend_article(string) do
    article = if string =~ ~r{^[aeiou]}i, do: "an", else: "a"

    article <> " " <> string
  end

  defp is_alias?(arg), do: arg =~ ~r{^-[^-]+}

  def get_arg_type(arg) do
    if arg |> is_alias? do
      arg = "-" <> arg
      opt = :aliases
    else
      opt = :strict
    end

    {_, config_arg, _, _} =
      arg
      |> List.wrap
      |> OptionParser.next


    @parse_opts[opt][config_arg]
  end

  def process_invalid_input({initial_config, argv, errors}) do
    

    {type_errors, name_errors} = 
      errors
      |> Enum.partition(fn({arg, val}) ->
        val
      end)

    errors
    |> Enum.map(fn({arg, val}) ->
      if val do
      type = 
        arg |> get_arg_type


    end)
  end

  def handle_errors(initial_config, errors) do
    IO.puts "error: #{arg} must be #{type |> Atom.to_string |> prepend_article}"

    parsed_val =
        val
        |> try_parse(type)
  end




 
  def handle_errors(parsed = {config, _, _}) when config[:help] do
    parsed
    |> help
  end

  def handle_errors({config, [], []})     do

  end
  def handle_errors(parsed = {config, invalid_input, []}),    do


    parsed
    |> handle_errors
  end
  def handle_errors({config, invalid_input, parse_errors}) do
    errors
      |> Enum.map(fn({input, }))
  end

  def handle_invalid_input(), do:
  if config[:frame_rate] do
      parsed = 
        invalid_input
        |> Enum.map(&Float.parse/1)
        |> Enum.filter_map(&(&1 != :error), fn({float, _}) ->
          float
        end)
        |> handle_floats
    end

  defp fetch_config!(config), do: :pachinko |> Application.get_env(config)
end