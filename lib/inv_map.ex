defmodule InvMap do
  @moduledoc """
  Documentation for `InvMap`.
  """

  defstruct forward: %{}, inverse: %{}

  @doc """
  Returns a new empty InvMap.

  ## Examples

      iex> InvMap.new()
      InvMap.new(%{})
  """
  def new, do: %InvMap{}

  @doc """
  Creates an InvMap from an `enumerable`.

  Duplicated keys are removed; the latest one prevails.

  ## Examples

      iex> InvMap.new(%{b: 1, a: 2})
      InvMap.new(%{a: 2, b: 1})
      iex> InvMap.new(a: 1, a: 2, a: 3)
      InvMap.new(%{a: 3})
  """
  def new(enumerable)
  def new(%InvMap{} = inv_map), do: inv_map

  def new(enumerable) do
    enumerable
    |> Map.new()
    |> new_from_map!()
  end

  @doc """
  Creates an InvMap from an `enumerable` via the given transformation function.

  Duplicated keys are removed; the latest one prevails.

  ## Examples

      iex> InvMap.new([1, 2], fn x -> {x, 100 * x + 1} end)
      InvMap.new(%{1 => 101, 2 => 201})
      iex> InvMap.new(%{a: 2, b: 3, c: 4}, fn {key, val} -> {key, val * 2} end)
      InvMap.new(%{a: 4, b: 6, c: 8})
  """
  def new(enumerable, transform)
  def new(%InvMap{forward: forward}, transform), do: new(forward, transform)

  def new(enumerable, transform) do
    enumerable
    |> Map.new(transform)
    |> new_from_map!()
  end

  defp new_from_map!(map) do
    inverse = Map.new(map, fn {k, v} -> {v, k} end)
    inv_map = %InvMap{forward: map, inverse: inverse}
    validate_involution_on_get!(inv_map)
  end

  defp validate_involution_on_get!(%InvMap{forward: forward} = inv_map) do
    f = fn key -> get(inv_map, key) end

    if Enum.all?(Map.keys(forward), fn x -> f.(f.(x)) === x end) do
      inv_map
    else
      raise ArgumentError, "InvMap does not implement an involution on get"
    end
  end

  @doc """
  Puts the given `value` under `key` in `inv_map`.

  ## Examples

      iex> InvMap.put(InvMap.new(), 1, 1.0)
      InvMap.new(%{1 => 1.0})
      iex> InvMap.put(InvMap.new(%{1 => 1.0, 2 => 2.0}), 1, 3.0)
      InvMap.new(%{1 => 3.0, 2 => 2.0})
      iex> InvMap.put(InvMap.new(%{1 => 1.0, 2 => 2.0}), 3, 1.0)
      InvMap.new(%{3 => 1.0, 2 => 2.0})
      iex> InvMap.put(InvMap.new(%{1 => 1.0, 2 => 2.0}), 1, 2.0)
      InvMap.new(%{1 => 2.0})
  """
  def put(%InvMap{} = inv_map, key, value) do
    %{forward: forward, inverse: inverse} =
      inv_map
      |> delete(key)
      |> delete(value)

    %InvMap{forward: Map.put(forward, key, value), inverse: Map.put(inverse, value, key)}
  end

  @doc """
  Fetches the value for a specific `key` in the given `inv_map`.

  If `inv_map` contains the given `key` then its value is returned in the shape of `{:ok, value}`.
  If `inv_map` doesn't contain `key`, `:error` is returned.

  ## Examples

      iex> InvMap.fetch(InvMap.new(a: 1), :a)
      {:ok, 1}
      iex> InvMap.fetch(InvMap.new(a: 1), 1)
      {:ok, :a}
      iex> InvMap.fetch(InvMap.new(a: 1), :b)
      :error
  """
  def fetch(%InvMap{} = inv_map, key) do
    case inv_map do
      %{forward: %{^key => value}} ->
        {:ok, value}

      %{inverse: %{^key => value}} ->
        {:ok, value}

      _ ->
        :error
    end
  end

  @doc """
  Fetches the value for a specific `key` in the given `inv_map`,
  erroring out if `inv_map` doesn't contain `key`.

  If `inv_map` contains `key`, the corresponding value is returned.
  If `inv_map` doesn't contain `key`, a `KeyError` exception is raised.

  ## Examples

      iex> InvMap.fetch!(InvMap.new(a: 1), :a)
      1
      iex> InvMap.fetch!(InvMap.new(a: 1), 1)
      :a
      iex> InvMap.fetch!(InvMap.new(a: 1), :b)
      ** (KeyError) key :b not found in:...
  """
  def fetch!(%InvMap{} = inv_map, key) do
    # TODO: fully test raise in ...test.exs
    case fetch(inv_map, key) do
      {:ok, value} -> value
      :error -> raise KeyError, key: key, term: inv_map
    end
  end

  @doc """
  Gets the value for the specific `key` in `inv_map`.

  If `key` is present in `inv_map` then its value is returned.
  Otherwise, `default` is returned.

  If `default` is not provided, `nil` is used.

  ## Examples

      iex> InvMap.get(InvMap.new(), :a)
      nil
      iex> InvMap.get(InvMap.new(), :a, 0)
      0
      iex> InvMap.get(InvMap.new(a: 1), :a)
      1
      iex> InvMap.get(InvMap.new(a: 1), 1)
      :a
      iex> InvMap.get(InvMap.new(a: nil), :a, 1)
      nil
  """
  def get(%InvMap{} = inv_map, key, default \\ nil) do
    case fetch(inv_map, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Deletes the entry in `inv_map` for a specific `key`.

  If the `key` does not exist, returns `inv_map` unchanged.

  ## Examples

      iex> InvMap.delete(InvMap.new(a: 1, b: 2), :a)
      InvMap.new(%{b: 2})
      iex> InvMap.delete(InvMap.new(a: 1, b: 2), 1)
      InvMap.new(%{b: 2})
      iex> InvMap.delete(InvMap.new(b: 2), :a)
      InvMap.new(%{b: 2})
  """
  def delete(%InvMap{} = inv_map, key) do
    inv_map
    |> maybe_delete_by_forward_key(key)
    |> maybe_delete_by_inverse_key(key)
  end

  defp maybe_delete_by_forward_key(%{forward: forward} = inv_map, key) do
    case forward do
      %{^key => value} ->
        inverse = inv_map.inverse
        %InvMap{forward: Map.delete(forward, key), inverse: Map.delete(inverse, value)}
      _ ->
        inv_map
    end
  end

  defp maybe_delete_by_inverse_key(%{inverse: inverse} = inv_map, key) do
    case inverse do
      %{^key => value} ->
        forward = inv_map.forward
        %InvMap{forward: Map.delete(forward, value), inverse: Map.delete(inverse, key)}
      _ ->
        inv_map
    end
  end

  @doc """
  Drops the given `keys` from `inv_map`.

  If `keys` contains keys that are not in `inv_map`, they're simply ignored.

  ## Examples

      iex> InvMap.drop(InvMap.new(a: 1, b: 2, c: 3), [:b, 3, :d])
      InvMap.new(%{a: 1})
  """
  def drop(%InvMap{} = inv_map, []), do: inv_map
  def drop(%InvMap{} = inv_map, [key | rest]), do: drop(delete(inv_map, key), rest)

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

  defimpl Inspect do
    def inspect(%InvMap{forward: forward}, %Inspect.Opts{} = opts) do
      # TODO: support for safer 1.19+ only inspect based on:
      # https://github.com/elixir-lang/elixir/blob/v1.19.5/lib/elixir/lib/map_set.ex#L444-L455
      # {doc, %{limit: limit}} = Inspect.Algebra.to_doc_with_opts(forward, opts)
      # {Inspect.Algebra.concat(["InvMap.new(", doc, ")"]), %{opts | limit: limit}}
      Inspect.Algebra.concat(["InvMap.new(", Inspect.Algebra.to_doc(forward, opts), ")"])
    end
  end
end
