use Mix.Config

# Configure your database
config :elixir_drip, ElixirDrip.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "elixir_drip_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
