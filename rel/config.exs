Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set dev_mode: true
  set include_erts: false
  set cookie: :"L9pTCob/l<)0&WTOFkCjg>OOVLw&HZivG;4=((5THJltA0V[a>.|dQ<liNdG9q=S"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"u]}g=H5@:&LRyc,}T4I$1@TU/>?Q*}D,q3.,;*`x)D`<~&4(:n.8~oGV.YDikP=8"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :elixir_drip do
  set version: "0.0.8"
  set applications: [
    :runtime_tools,
    elixir_drip: :permanent,
    elixir_drip_web: :permanent
  ]
end

