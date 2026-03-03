defmodule InvMap do
  @moduledoc """
  Documentation for `InvMap`.
  """

  defstruct forward: %{}, inverse: %{}

  @doc """
  Returns a new empty InvMap.

  ## Examples

      iex> InvMap.new()
      %InvMap{forward: %{}, inverse: %{}}

  """
  def new do
    %InvMap{}
  end

  @doc """
  Puts the given `value` under `key` in `inv_map`.

  ## Examples

      iex> InvMap.put(InvMap.new(), :a, 1)
      %InvMap{forward: %{:a => 1}, inverse: %{1 => :a}}

  """
  def put(%InvMap{forward: forward, inverse: inverse} = inv_map, key, value) do
    # TODO: check for existing keys
    %{inv_map | forward: Map.put(forward, key, value), inverse: Map.put(inverse, value, key)}
  end

  @doc """
  Gets the valu for the specific `key` in `inv_map`.

  if `key` is present in `inv_map` then its value is returned.
  Otherwise, `default` is returned.

  If `default` is not provided, `nil` is used.

  ## Examples

      iex> InvMap.get(InvMap.new(), :a)
      nil
      iex> InvMap.get(InvMap.new(), :a, 0)
      0

  """
  def get(%InvMap{forward: forward, inverse: inverse}, key, default \\ nil) do
    # TODO: rewrite like https://github.com/elixir-lang/elixir/blob/v1.19.5/lib/elixir/lib/map.ex#L532 ?
    Map.get_lazy(forward, key, fn -> Map.get(inverse, key, default) end)
  end
end
