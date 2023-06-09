import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cloudinary_demo, CloudinaryDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "o3xRfFVnLCTMe/OMLaJPKwLRmAsQzX/e7dp9tqfq0Lh8QdSJGliO5xg14EgFPjqe",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
