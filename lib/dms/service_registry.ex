defmodule DMS.ServiceRegistry do
  @registry_name __MODULE__

  defmacro __using__(_opts) do
    quote do
      import DMS.ServiceRegistry, only: [via_registry: 1, whereis_name: 1, exists?: 1]
    end
  end

  @doc "Child Specification for `#{__MODULE__}`"
  @spec child_spec :: map()
  def child_spec() do
    %{
      id: __MODULE__,
      start: {Registry, :start_link, [[keys: :unique, name: @registry_name]]}
    }
  end

  @spec via_registry(DMS.id) :: tuple()
  def via_registry(ref) do
    {:via, Registry, {@registry_name, ref}}
  end

  def whereis_name(ref) do
    Registry.whereis_name({@registry_name, ref})
  end

  def exists?(ref), do: whereis_name(ref) != :undefined
end
