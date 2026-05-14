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

  If the `enumerable` contains inverse pairs (e.g., `{1,2}` and `{2,1}`),
  only one is kept. Which one is kept is undefined.

  ## Examples

      iex> InvMap.new(%{b: 1, a: 2})
      InvMap.new(%{a: 2, b: 1})
      iex> InvMap.new(a: 1, a: 2, a: 3)
      InvMap.new(%{a: 3})

      # Inverse pairs are deduplicated. Which remains is undefined.
      InvMap.new([{1, 2}, {2, 1}])
      InvMap.new(%{1 => 2})
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

  If the transformed `enumerable` contains inverse pairs (e.g., `{1,2}` and `{2,1}`),
  only one is kept. Which one is kept is undefined.

  ## Examples

      iex> InvMap.new([1, 2], fn x -> {x, 100 * x + 1} end)
      InvMap.new(%{1 => 101, 2 => 201})
      iex> InvMap.new(%{a: 2, b: 3, c: 4}, fn {key, val} -> {key, val * 2} end)
      InvMap.new(%{a: 4, b: 6, c: 8})

      # Inverse pairs are deduplicated. Which remains is undefined.
      InvMap.new([{1, 4}, {2, 2}], fn {key, val} -> {key, div(val, 2)} end)
      InvMap.new(%{1 => 2})
  """
  def new(enumerable, transform)
  def new(%InvMap{forward: forward}, transform), do: new(forward, transform)

  def new(enumerable, transform) do
    enumerable
    |> Map.new(transform)
    |> new_from_map!()
  end

  defp new_from_map!(map) do
    forward = dedup_inverse_pairs(map)
    inverse = Map.new(forward, fn {k, v} -> {v, k} end)
    inv_map = %InvMap{forward: forward, inverse: inverse}
    validate_involution_on_get!(inv_map)
  end

  defp dedup_inverse_pairs(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      case acc do
        %{^v => ^k} -> acc
        _ -> Map.put(acc, k, v)
      end
    end)
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
  Puts the given key-value pair into `inv_map` unless
  `key` or `value` already exists in `inv_map`.

  ## Examples

      iex> InvMap.put_new(InvMap.new(a: 1), :b, 2)
      InvMap.new(%{a: 1, b: 2})
      iex> InvMap.put_new(InvMap.new(a: 1, b: 2), :a, 3)
      InvMap.new(%{a: 1, b: 2})
      iex> InvMap.put_new(InvMap.new(a: 1, b: 2), :c, 1)
      InvMap.new(%{a: 1, b: 2})
  """
  def put_new(%InvMap{} = inv_map, key, value) do
    if has_key?(inv_map, key) or has_key?(inv_map, value) do
      inv_map
    else
      put(inv_map, key, value)
    end
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
  Gets the value for a specific `key` in `inv_map`.

  If `key` is present in `inv_map` then its value is returned.
  Otherwise, `fun` is evaluated and its result is returned.

  This is useful if the default value is very expensive to calculate or
  generally difficult to setup and teardown again.

  ## Examples

      iex> inv_map = InvMap.new(a: 1)
      iex> fun = fn ->
      ...>   # some expensive operation here
      ...>   "fun invoked"
      ...> end
      iex> InvMap.get_lazy(inv_map, :a, fun)
      1
      iex> InvMap.get_lazy(inv_map, 1, fun)
      :a
      iex> InvMap.get_lazy(inv_map, "missing", fun)
      "fun invoked"
  """
  def get_lazy(%InvMap{} = inv_map, key, fun) when is_function(fun, 0) do
    case fetch(inv_map, key) do
      {:ok, value} -> value
      :error -> fun.()
    end
  end

  @doc """
  Updates the `key` in `inv_map` with the given function.

  If `key` is present in `inv_map` then the existing value is passed to `fun` and its result is
  used as the updated value of `key`. If `key` is
  not present in `inv_map`, `default` is inserted as the value of `key`. The default
  value will not be passed through the update function.

  ## Examples

      iex> InvMap.update(InvMap.new(one: 1), :one, "miss", fn value -> to_string(value) end)
      InvMap.new(%{one: "1"})
      iex> InvMap.update(InvMap.new(one: 1), 1, "miss", fn value -> to_string(value) end)
      InvMap.new(%{1 => "one"})
      iex> InvMap.update(InvMap.new(one: 1), :two, "miss", fn value -> to_string(value) end)
      InvMap.new(%{one: 1, two: "miss"})
  """
  def update(%InvMap{} = inv_map, key, default, fun) when is_function(fun, 1) do
    case fetch(inv_map, key) do
      {:ok, value} -> put(inv_map, key, fun.(value))
      :error -> put(inv_map, key, default)
    end
  end

  @doc """
  Updates `key` with the given function.

  If `key` is present in `inv_map` then the existing value is passed to `fun` and its result is
  used as the updated value of `key`. If `key` is
  not present in `inv_map`, a `KeyError` exception is raised.

  ## Examples

      iex> InvMap.update!(InvMap.new(one: 1), :one, fn value -> to_string(value) end)
      InvMap.new(%{one: "1"})
      iex> InvMap.update!(InvMap.new(one: 1), 1, fn value -> to_string(value) end)
      InvMap.new(%{1 => "one"})
      iex> InvMap.update!(InvMap.new(one: 1), :two, fn value -> to_string(value) end)
      ** (KeyError) key :two not found in:...
  """
  def update!(%InvMap{} = inv_map, key, fun) when is_function(fun, 1) do
    value = fetch!(inv_map, key)
    put(inv_map, key, fun.(value))
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
    case inv_map do
      %{forward: %{^key => value} = forward} ->
        inverse = inv_map.inverse
        %InvMap{forward: Map.delete(forward, key), inverse: Map.delete(inverse, value)}

      %{inverse: %{^key => value} = inverse} ->
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
  Checks if two `InvMap`s are equal.

  Two `InvMap`s are considered to be equal if they contain the same
  key-value pairs, without respect to the direction of each pair.
  In other words, pair `{k, v}` is considered equal to pair `{v, k}`.

  Note this function returns different results than directly comparing
  `InvMap`s using `==/2` and `===/2`. Those compare structure, meaning
  `InvMap.new(%{1 => 2}) === InvMap.new(%{2 => 1})` returns `false`.

  ## Examples

      iex> InvMap.equal?(InvMap.new(a: 1, b: 2), InvMap.new(b: 2, a: 1))
      true
      iex> InvMap.equal?(InvMap.new(a: 1, b: 2), InvMap.new(b: 1, a: 2))
      false
      iex> InvMap.equal?(InvMap.new(%{1 => 2}), InvMap.new(%{2 => 1}))
      true

  Comparison between keys and values is done with strict equality,
  which means integers are not equivalent to floats:

      iex> InvMap.equal?(InvMap.new(a: 1.0), InvMap.new(a: 1))
      false
  """
  def equal?(%InvMap{forward: forward1}, %InvMap{forward: forward2} = inv_map2) do
    map_size(forward1) == map_size(forward2) and
      Enum.all?(forward1, fn {k, v} -> match?({:ok, ^v}, fetch(inv_map2, k)) end)
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

  @doc """
  Returns an `InvMap` containing only those pairs from `inv_map`
  for which `fun` returns a truthy value.

  `fun` receives the key and value of each of the
  elements in `inv_map` as a key-value pair.

  See also `reject/2` which discards all elements where the
  function returns a truthy value.

  > #### Performance considerations {: .tip}
  >
  > If you find yourself doing multiple calls to `InvMap.filter/2`
  > and/or `InvMap.reject/2` in a pipeline, it is likely more efficient
  > to use `Enum.filter/2` and `Enum.reject/2` instead and convert to
  > an `InvMap` at the end using `InvMap.new/1` or `InvMap.new/2`.

  ## Examples

      iex> InvMap.filter(InvMap.new(one: 1, two: 2), fn {_key, val} -> rem(val, 2) == 1 end)
      InvMap.new(%{one: 1})
  """
  def filter(%InvMap{forward: forward}, fun) when is_function(fun, 1) do
    forward
    |> Map.filter(fun)
    |> InvMap.new()
  end

  @doc """
  Returns an `InvMap` excluding the pairs from `inv_map`
  for which `fun` returns a truthy value.

  See also `filter/2`.

  > #### Performance considerations {: .tip}
  >
  > If you find yourself doing multiple calls to `InvMap.filter/2`
  > and/or `InvMap.reject/2` in a pipeline, it is likely more efficient
  > to use `Enum.filter/2` and `Enum.reject/2` instead and convert to
  > an `InvMap` at the end using `InvMap.new/1` or `InvMap.new/2`.

  ## Examples

      iex> InvMap.reject(InvMap.new(one: 1, two: 2), fn {_key, val} -> rem(val, 2) == 1 end)
      InvMap.new(%{two: 2})
  """
  def reject(%InvMap{forward: forward}, fun) when is_function(fun, 1) do
    forward
    |> Map.reject(fun)
    |> InvMap.new()
  end

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
