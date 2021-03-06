defmodule DMS.Service do
  @moduledoc """
  Service Actor respresenting an active service.
  Will terminate if there has not been a `ping/1` against a `DMS.id` within `@timeout`.
  """
  use GenServer

  import DMS.Service.Registry, only: [via_registry: 1, exists?: 1]

  require Logger

  @server __MODULE__
  @supervisor DMS.Service.Supervisor
  # TODO Make timeout configurable.
  @timeout 5 * 1000

  @doc """
  Signals service is alive.
  Returns pong if signal was successful, otherwise pang.
  """
  @spec ping(DMS.id()) :: :pong | :pang
  def ping(id) do
    child_spec = %{
      id: id,
      restart: :temporary,
      start: {__MODULE__, :start_link, [id]}
    }

    case DynamicSupervisor.start_child(@supervisor, child_spec) do
      {:ok, _} ->
        GenServer.cast(via_registry(id), :ping)
        :pong

      {:error, {:already_started, _}} ->
        GenServer.cast(via_registry(id), :ping)
        :pong
    end
  end

  @doc """
  Respond with `true` if service has been pinged within `@timeout`
  otherwise false.
  """
  @spec alive?(DMS.id()) :: boolean
  def alive?(id) do
    exists?(id)
  end

  @doc false
  def start_link(args) do
    id = args
    GenServer.start_link(@server, args, name: via_registry(id))
  end

  @doc false
  @impl GenServer
  def init(args) do
    id = args
    Logger.debug("[id: #{id}] New service registered.")
    {:ok, %{id: id, timer_ref: kill_switch()}}
  end

  @doc false
  @impl GenServer
  def handle_cast(:ping, state) do
    Logger.info("[id: #{state.id}] Ping received.")
    Process.cancel_timer(state.timer_ref)
    {:noreply, %{state | timer_ref: kill_switch()}}
  end

  @doc false
  @impl GenServer
  def handle_info(:die, state) do
    Logger.info("[id: #{state.id}] Kill signal received ~ terminating!")
    {:stop, :normal, state}
  end

  @doc false
  def kill_switch() do
    Process.send_after(self(), :die, @timeout)
  end
end
