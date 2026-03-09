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
  def new, do: %InvMap{}

  @doc """
  Creates an InvMap from an `enumerable`.

  Duplicated keys are removed; the latest one prevails.

  ## Examples

      iex> InvMap.new(%{b: 1, a: 2})
      %InvMap{forward: %{:b => 1, :a => 2}, inverse: %{1 => :b, 2 => :a}}
      iex> InvMap.new(a: 1, a: 2, a: 3)
      %InvMap{forward: %{:a => 3}, inverse: %{3 => :a}}

  """
  def new(enumerable)
  def new(%InvMap{} = inv_map), do: inv_map

  def new(enumerable) do
    enumerable
    |> Map.new()
    |> new_from_map()
  end

  defp new_from_map(map) do
    %InvMap{forward: map, inverse: Map.new(map, fn {k, v} -> {v, k} end)}
  end

  @doc """
  Creates an InvMap from an `enumerable` via the given transformation function.

  Duplicated keys are removed; the latest one prevails.

  ## Examples

      iex> InvMap.new([1, 2], fn x -> {x, 100 * x + 1} end)
      %InvMap{forward: %{1 => 101, 2 => 201}, inverse: %{101 => 1, 201 => 2}}
      iex> InvMap.new(%{a: 2, b: 3, c: 4}, fn {key, val} -> {key, val * 2} end)
      %InvMap{forward: %{:a => 4, :b => 6, :c => 8}, inverse: %{4 => :a, 6 => :b, 8 => :c}}

  """
  def new(enumerable, transform)
  def new(%InvMap{forward: forward}, transform), do: new(forward, transform)

  def new(enumerable, transform) do
    enumerable
    |> Map.new(transform)
    |> new_from_map()
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
