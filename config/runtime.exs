import Config
import Dotenvy

source!([".env", System.get_env()])

config :demeter, Demeter.Repo,
  database: env!("DB_DATABASE"),
  username: env!("DB_USER"),
  password: env!("DB_PASSWORD"),
  hostname: env!("DB_HOST")
