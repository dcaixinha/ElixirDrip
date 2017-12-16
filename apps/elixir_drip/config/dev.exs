use Mix.Config

# Configure your database
config :elixir_drip, ElixirDrip.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "elixir_drip_dev",
  hostname: "localhost",
  pool_size: 10
