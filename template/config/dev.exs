use Mix.Config

config :phoenix, <%= application_module %>.Router,
  port: System.get_env("PORT") || 4000,
  ssl: false,
  host: "localhost",
  code_reload: true,
  cookies: true,
  consider_all_requests_local: true,
  session_key: "_<%= application_name %>_key",
  session_secret: "<%= session_secret %>"

config :phoenix, :logger,
  level: :debug


