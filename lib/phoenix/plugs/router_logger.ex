defmodule Phoenix.Plugs.RouterLogger do
  import Phoenix.Controller.Connection
  require Logger

  @moduledoc """
  Plug to handle request logging at the router level

  Includes basic request logging of HTTP method and conn.path_info
  """

  def init(opts), do: opts

  def call(conn, _level) do
    Plug.Conn.register_before_send(conn, fn (conn) -> 
      content_type = conn.private[:phoenix_content_type] || nil
      Logger.debug """ 
      Processing by #{controller_module(conn)}.#{action_name(conn)}
        Accept: #{content_type}
        Parameters: #{inspect conn.params}
      """
      conn
    end)
  end
end
