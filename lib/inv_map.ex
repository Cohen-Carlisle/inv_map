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

  @doc """
  Deletes the entry in `inv_map` for a specific `key`.

  If the `key` does not exist, returns `inv_map` unchanged.

  ## Examples

      iex> InvMap.delete(InvMap.new(a: 1, b: 2), :a)
      %InvMap{forward: %{:b => 2}, inverse: %{2 => :b}}
      iex> InvMap.delete(InvMap.new(a: 1, b: 2), 1)
      %InvMap{forward: %{:b => 2}, inverse: %{2 => :b}}
      iex> InvMap.delete(InvMap.new(b: 2), :a)
      %InvMap{forward: %{:b => 2}, inverse: %{2 => :b}}
  """
  def delete(%InvMap{forward: forward, inverse: inverse} = inv_map, key) do
    cond do
      Map.has_key?(forward, key) ->
        value = Map.get(forward, key)
        %InvMap{forward: Map.delete(forward, key), inverse: Map.delete(inverse, value)}

      Map.has_key?(inverse, key) ->
        value = Map.get(inverse, key)
        %InvMap{forward: Map.delete(forward, value), inverse: Map.delete(inverse, key)}

      true ->
        inv_map
    end
  end

  @doc """
  Returns whether the given `key` exists in the given `inv_map`.

  ## Examples

      iex> InvMap.has_key?(InvMap.new(a: 1), :a)
      true
      iex> InvMap.has_key?(InvMap.new(a: 1), 1)
      true
      iex> InvMap.has_key?(InvMap.new(a: 1), :b)
      false
  """
  def has_key?(%InvMap{forward: forward, inverse: inverse}, key) do
    Map.has_key?(forward, key) || Map.has_key?(inverse, key)
  end

  @doc """
  Converts `inv_map` to a list.

  Each entry in the `inv_map` is converted to a two-element tuple
  `{key, value}` in the resulting list.

  ## Examples

      iex> InvMap.to_list(InvMap.new(%{a: 1}))
      [a: 1]
      iex> InvMap.to_list(InvMap.new(%{1 => 2}))
      [{1, 2}]
  """
  def to_list(%InvMap{forward: forward}), do: Map.to_list(forward)
end
