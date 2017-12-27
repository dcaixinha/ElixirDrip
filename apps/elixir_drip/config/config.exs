use Mix.Config

config :elixir_drip, ecto_repos: [ElixirDrip.Repo]

import_config "#{Mix.env()}.exs"
