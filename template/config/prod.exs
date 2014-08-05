use Mix.Config

config :phoenix, <%= application_module %>.Router,
  port: System.get_env("PORT"),
  ssl: false,
  code_reload: false,
  cookies: true,
  session_key: "_<%= Mix.Utils.underscore(application_module) %>_key",
  session_secret: "<%= session_secret %>"

config :logger, :console
  level: :info
