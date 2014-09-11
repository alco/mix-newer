defmodule MixNewer.Eval do
  @moduledoc """
  Functions related to evaluating user scripts in templates.
  """

  def eval_defs(config, overrides, args) do
    vars = [config: config, user_config: [], flags: []]
    bindings = eval_script("_template_config/defs.exs", :defs, vars)

    flags = Keyword.fetch!(bindings, :flags)
    user_flags = case OptionParser.parse(args, strict: flags) do
      {opts, [], []} ->
        opts
      {_, [arg|_], _} ->
        Mix.raise "Extraneous argument: #{arg}"
      {_, _, [{opt, _}]} ->
        Mix.raise "Undefine user option #{opt}"
    end

    user_config =
      config
      |> Map.merge(Keyword.fetch!(bindings, :user_config) |> Enum.into(%{}))
      |> MixNewer.Config.apply_overrides(overrides)

    {user_config, user_flags}
  end

  def eval_init(config, flags) do
    vars = [config: config, flags: flags, actions: []]
    eval_script("_template_config/init.exs", :init, vars)
    |> Keyword.fetch!(:actions)
  end

  defp eval_script(path, env_id, vars) do
    code = File.read!(path) |> Code.string_to_quoted!
    env = make_env_for(env_id)
    {_, bindings} = Code.eval_quoted(code, vars, env)
    bindings
  end

  defp make_env_for(:defs) do
    import MixNewer.Macros, only: [flag: 2, param: 2], warn: false
    __ENV__
  end

  defp make_env_for(:init) do
    import MixNewer.Macros, only: [select: 2], warn: false
    __ENV__
  end
end