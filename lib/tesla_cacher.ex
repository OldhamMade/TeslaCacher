defmodule Tesla.Middleware.Cacher do
  @behaviour Tesla.Middleware

  @moduledoc """
  Cache the result in redis.

  ### Example
  ```elixir
  defmodule MyClient do
    use Tesla

    plug Tesla.Middleware.Cacher,
      redix: :redix,
      expiry: :timer.seconds(2),
      timeout: :timer.seconds(5),
      prefix: :tesla_cacher
  end
  ```
  """

  require Logger

  @redix_timeout 5000

  @impl true
  def call(env, next, opts) do
    opts = [
      redix: Keyword.fetch!(opts, :redix),
      expiry: Keyword.get(opts, :expiry, :infinity),
      timeout: Keyword.get(opts, :timeout, @redix_timeout),
      prefix: Keyword.get(opts, :prefix, :tesla_cacher)
    ]

    env
    |> lookup(opts)
    |> run(next)
    |> insert(opts)
  end

  def lookup(%Tesla.Env{method: :get} = env, opts) do
    key = make_key(env, opts)
    {redix_lookup(key, opts), env}
  end

  def lookup(env, _), do: {:miss, env}

  def run({{:hit, env}, _}, _next) when not is_nil(env) do
    {:hit, env}
  end

  def run({_, env}, next) do
    Tesla.run(env, next)
    |> handle_run()
  end

  def insert({:miss, %Tesla.Env{method: :get, status: status} = env}, opts) when status == 200 do
    key = make_key(env, opts)
    value = :erlang.term_to_binary(env)
    status = redix_insert(key, value, opts)

    {status, env}
  end

  def insert({_, %Tesla.Env{} = env}, _opts), do: {:ok, env}
  def insert(result, _opts), do: result

  # private

  defguardp is_conn(value) when is_atom(value) or is_pid(value)

  defp make_key(%Tesla.Env{url: url, query: query},
         redix: _,
         expiry: _,
         timeout: _,
         prefix: prefix
       ) do
    fqurl = Tesla.build_url(url, query)
    "#{prefix}|#{fqurl}"
  end

  defp redix_lookup(key, redix: conn, expiry: _, timeout: timeout, prefix: _)
       when is_conn(conn) do
    Redix.command(conn, ["GET", key], timeout: timeout)
    |> handle_redix_lookup()
  end

  defp handle_redix_lookup({_, nil}) do
    {:miss, nil}
  end

  defp handle_redix_lookup({:ok, result}) do
    {:hit, :erlang.binary_to_term(result)}
  end

  defp handle_redix_lookup({_, msg}) do
    Logger.warn("TeslaCacher: unexpected cache miss: #{inspect msg}")
    {:miss, msg}
  end

  defp handle_run({:error, :timeout} = result), do: result
  defp handle_run({:ok, env}), do: {:miss, env}

  defp redix_insert(key, value, redix: conn, expiry: ttl, timeout: timeout, prefix: _)
       when is_conn(conn) and is_integer(ttl) do
    Redix.command(conn, ["SET", key, value, "PX", ttl], timeout: timeout)
    |> handle_redix_insert()
  end

  defp redix_insert(key, value, redix: conn, expiry: _, timeout: timeout, prefix: _)
       when is_conn(conn) do
    Redix.command(conn, ["SET", key, value], timeout: timeout)
    |> handle_redix_insert()
  end

  defp handle_redix_insert({:ok, _}), do: :ok
  defp handle_redix_insert(result) do
    Logger.warn("TeslaCacher: unable to insert, got: #{inspect result}")
    :ok
  end
end
