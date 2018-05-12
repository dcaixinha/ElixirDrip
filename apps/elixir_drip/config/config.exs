use Mix.Config

config :elixir_drip, ecto_repos: [ElixirDrip.Repo]

config :elixir_drip,
  storage_provider: ElixirDrip.Storage.Providers.GoogleCloudStorage.Local

config :arc,
  storage: Arc.Storage.GCS,
  bucket: "elixir-drip-andre-development",
  storage_dir: "v1"

config :goth,
  json: "./secrets/credentials.dev.json" |> Path.expand |> File.read!

import_config "#{Mix.env()}.exs"
