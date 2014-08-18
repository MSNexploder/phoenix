defmodule Phoenix.Router do
  alias Phoenix.Plugs
  alias Phoenix.Router.Options
  alias Phoenix.Adapters.Cowboy
  alias Phoenix.Plugs.Parsers
  alias Phoenix.Config
  alias Phoenix.Project

  defmacro __using__(plug_adapter_options \\ []) do
    quote do
      use Phoenix.Router.Mapper
      use Phoenix.Adapters.Cowboy

      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      use Plug.Builder

      if Config.router(__MODULE__, [:static_assets]) do
        mount = Config.router(__MODULE__, [:static_assets_mount])
        plug Plug.Static, at: mount, from: Project.app
      end
      if Config.router(__MODULE__, [:parsers]) do
        plug Plug.Parsers, parsers: [:urlencoded, :multipart, Parsers.JSON], accept: ["*/*"]
      end
      if Config.router(__MODULE__, [:error_handler]) do
        plug Plugs.ErrorHandler, from: __MODULE__
      end

      @options unquote(plug_adapter_options)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      plug Plug.Logger
      plug Plugs.RouterLogger
      if Config.router(__MODULE__, [:code_reload]) do
        plug Plugs.CodeReloader
      end
      if Config.router(__MODULE__, [:cookies]) do
        key    = Config.router!(__MODULE__, [:session_key])
        secret = Config.router!(__MODULE__, [:session_secret])

        plug Plug.Session, store: :cookie, key: key, secret: secret
        plug Plugs.SessionFetcher
      end

      plug Plug.MethodOverride

      unless Plugs.plugged?(@plugs, :dispatch) do
        plug :dispatch
      end

      def dispatch(conn, []) do
        Phoenix.Router.perform_dispatch(conn, __MODULE__)
      end

      def start do
        options = Options.merge(@options, @dispatch_options, __MODULE__, Cowboy)
        Phoenix.Router.start_adapter(__MODULE__, options)
      end

      def stop do
        options = Options.merge(@options, @dispatch_options, __MODULE__, Cowboy)
        Phoenix.Router.stop_adapter(__MODULE__, options)
      end
    end
  end

  @doc """
  Starts the Router module with provided List of options
  """
  def start_adapter(module, opts) do
    protocol = if opts[:ssl], do: :https, else: :http
    case apply(Plug.Adapters.Cowboy, protocol, [module, [], opts]) do
      {:ok, pid} ->
        "%{green}Running #{module} with Cowboy on port #{inspect opts[:port]}%{reset}"
        |> IO.ANSI.escape
        |> IO.puts
        {:ok, pid}

      {:error, :eaddrinuse} ->
        raise "Port #{inspect opts[:port]} is already in use"
    end
  end

  @doc """
  Stops the Router module with provided List of options
  """
  def stop_adapter(module, opts) do
    protocol = if opts[:ssl], do: HTTPS, else: HTTP
    apply(Plug.Adapters.Cowboy, :shutdown, [Module.concat(module, protocol)])
    IO.puts "#{module} has been stopped"
  end

  @doc """
  Carries out Controller dispatch for router match
  """
  def perform_dispatch(conn, router) do
    router.match(conn, conn.method, conn.path_info)
  end
end
