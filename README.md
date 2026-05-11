# InvMap

A bidirectional `Map` for Elixir.

`InvMap` mirrors the public API of the standard `Map` module (WIP), but its
lookups are symmetric: `get(m, key)` and `get(m, value)` both return the
counterpart. This is useful when the key-value relationship is 1-to-1 and you
want lookups from both directions.

## Involution

Looking up any key in an `InvMap` and then looking up the result gets you back
the original key. In other words, `get/2` is a self-inverting function, or an
[involution](https://en.wikipedia.org/wiki/Involution_(mathematics)).
This means no keys can share a value, and no key can collide with a value.
`InvMap` enforces this for you: violating inputs are rejected in `new/{1,2}`,
and `put/3` drops conflicting entries to keep the involution intact,
similar to how `Map.put` overwrites a conflicting key.

## Examples

```elixir
iex> country_codes = InvMap.new(%{"BR" => "Brazil", "US" => "United States"})
InvMap.new(%{"BR" => "Brazil", "US" => "United States"})
iex> InvMap.get(country_codes, "BR")
"Brazil"
iex> InvMap.get(country_codes, "Brazil")
"BR"

# Inserting {:a, 2} into InvMap.new(%{a: 1, b: 2}) would collide with both
# {:a, 1} and {:b, 2}, so put/3 drops both entries to preserve the involution.
iex> InvMap.put(InvMap.new(%{a: 1, b: 2}), :a, 2)
InvMap.new(%{a: 2})
```

## Installation

Once published to Hex, add `inv_map` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:inv_map, "~> 0.1.0"}
  ]
end
```

Documentation will be available at <https://hexdocs.pm/inv_map>.
