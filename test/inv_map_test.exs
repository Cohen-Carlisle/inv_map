defmodule InvMapTest do
  use ExUnit.Case
  doctest InvMap

  describe "new/0" do
    test "returns a new empty InvMap" do
      assert InvMap.new() == %InvMap{forward: %{}, inverse: %{}}
    end
  end

  describe "new/1" do
    test "creates an InvMap from an enumerable" do
      expected = %InvMap{forward: %{:a => 1, :b => 2}, inverse: %{1 => :a, 2 => :b}}
      assert InvMap.new(%{a: 1, b: 2}) == expected
      assert InvMap.new([{:a, 1}, {:b, 2}]) == expected
      assert InvMap.new(MapSet.new(a: 1, b: 2)) == expected
    end

    # TODO: make InvMap enumerable
    test "creates an InvMap from an InvMap" do
      expected = %InvMap{forward: %{:a => 1, :b => 2}, inverse: %{1 => :a, 2 => :b}}
      assert InvMap.new(expected) == expected
    end

    test "the last key in wins" do
      expected = %InvMap{forward: %{:a => 3}, inverse: %{3 => :a}}
      assert InvMap.new(a: 1, a: 2, a: 3) == expected
    end

    test "deduplicates inverse pairs, but which remains is undefined" do
      inv_map = InvMap.new([{1, 2}, {2, 1}])
      assert map_size(inv_map.forward) == 1
      assert InvMap.get(inv_map, 1) == 2
      assert InvMap.get(inv_map, 2) == 1
    end

    test "raises ArgumentError when enumerable is not self-inverting" do
      assert_raise ArgumentError, fn -> InvMap.new(%{1 => 2, 2 => 3}) end
      assert_raise ArgumentError, fn -> InvMap.new(%{a: 1, b: 1}) end
      assert_raise ArgumentError, fn -> InvMap.new(%{1 => :a, 1.0 => :a}) end
    end
  end

  describe "new/2" do
    test "creates an InvMap from an enumerable" do
      expected = %InvMap{forward: %{:a => 2, :b => 4}, inverse: %{2 => :a, 4 => :b}}
      assert InvMap.new(%{a: 1, b: 2}, fn {x, y} -> {x, y * 2} end) == expected
      assert InvMap.new([{:a, 1}, {:b, 2}], fn {x, y} -> {x, y * 2} end) == expected
      assert InvMap.new(MapSet.new(a: 1, b: 2), fn {x, y} -> {x, y * 2} end) == expected
    end

    # TODO: make InvMap enumerable
    test "creates an InvMap from an InvMap" do
      expected = %InvMap{forward: %{:a => 2, :b => 4}, inverse: %{2 => :a, 4 => :b}}
      assert InvMap.new(InvMap.new(a: 1, b: 2), fn {x, y} -> {x, y * 2} end) == expected
    end

    test "the last key in wins" do
      expected = %InvMap{forward: %{:a => 6}, inverse: %{6 => :a}}
      assert InvMap.new([a: 1, a: 2, a: 3], fn {x, y} -> {x, y * 2} end) == expected
    end

    test "deduplicates inverse pairs, but which remains is undefined" do
      inv_map = InvMap.new([{1, 4}, {2, 2}], fn {key, val} -> {key, div(val, 2)} end)
      assert map_size(inv_map.forward) == 1
      assert InvMap.get(inv_map, 1) == 2
      assert InvMap.get(inv_map, 2) == 1
    end

    test "raises ArgumentError when transformed enumerable is not self-inverting" do
      assert_raise ArgumentError, fn -> InvMap.new([1, 2], &{&1, &1 + 1}) end
      assert_raise ArgumentError, fn -> InvMap.new([:a, :b], &{&1, 1}) end
      assert_raise ArgumentError, fn -> InvMap.new([1, 1.0], &{&1, :a}) end
    end
  end

  describe "put/3" do
    test "puts the key value pair in inv_map" do
      assert InvMap.put(InvMap.new(), :a, 1) == %InvMap{forward: %{:a => 1}, inverse: %{1 => :a}}
    end
  end

  describe "put_new/3" do
    test "puts the key value pair in inv_map if the key is not already present" do
      expected = %InvMap{forward: %{a: 1, b: 2}, inverse: %{1 => :a, 2 => :b}}
      assert InvMap.put_new(InvMap.new(a: 1), :b, 2) == expected
    end

    test "returns inv_map unchanged if the key or value is already present" do
      inv_map = InvMap.new(a: 1, b: 2)
      assert InvMap.put_new(inv_map, :a, 3) == inv_map
      assert InvMap.put_new(inv_map, 3, :a) == inv_map
      assert InvMap.put_new(inv_map, :c, 1) == inv_map
      assert InvMap.put_new(inv_map, 1, :c) == inv_map
    end
  end

  describe "get/3" do
    test "returns the value of key in inv_map, else default" do
      inv_map = InvMap.new()
      inv_map = InvMap.put(inv_map, :a, 1)
      assert InvMap.get(inv_map, :a) == 1
      assert InvMap.get(inv_map, 1) == :a
      assert InvMap.get(inv_map, :no) == nil
      assert InvMap.get(inv_map, :no, :yes) == :yes
    end
  end

  describe "get_lazy/3" do
    test "returns the value of key in inv_map, else invokes fun" do
      inv_map = InvMap.new(a: 1)
      fun = fn -> send(self(), "fun invoked") end

      assert InvMap.get_lazy(inv_map, :a, fun) == 1
      refute_received "fun invoked"

      assert InvMap.get_lazy(inv_map, 1, fun) == :a
      refute_received "fun invoked"

      assert InvMap.get_lazy(inv_map, "missing", fun) == "fun invoked"
      assert_received "fun invoked"
    end

    test "raises FunctionClauseError when fun arity is not 0" do
      assert_raise FunctionClauseError, fn ->
        InvMap.get_lazy(InvMap.new(a: 1), :a, fn _ -> 1 end)
      end
    end
  end

  describe "update/4" do
    test "updates the value when the key is in the forward map" do
      expected = %InvMap{forward: %{one: "1"}, inverse: %{"1" => :one}}
      assert InvMap.update(InvMap.new(one: 1), :one, "miss", &to_string/1) == expected
    end

    test "updates the value when the key is in the inverse map" do
      expected = %InvMap{forward: %{1 => "one"}, inverse: %{"one" => 1}}
      assert InvMap.update(InvMap.new(one: 1), 1, "miss", &to_string/1) == expected
    end

    test "inserts default when the key is not present" do
      expected = %InvMap{forward: %{one: 1, two: "miss"}, inverse: %{1 => :one, "miss" => :two}}
      assert InvMap.update(InvMap.new(one: 1), :two, "miss", &to_string/1) == expected
    end

    test "raises FunctionClauseError when fun arity is not 1" do
      assert_raise FunctionClauseError, fn ->
        InvMap.update(InvMap.new(one: 1), :one, "miss", fn -> :oops end)
      end

      assert_raise FunctionClauseError, fn ->
        InvMap.update(InvMap.new(one: 1), :one, "miss", fn _, _ -> :oops end)
      end
    end
  end

  describe "update!/3" do
    test "updates the value when the key is in the forward map" do
      expected = %InvMap{forward: %{one: "1"}, inverse: %{"1" => :one}}
      assert InvMap.update!(InvMap.new(one: 1), :one, &to_string/1) == expected
    end

    test "updates the value when the key is in the inverse map" do
      expected = %InvMap{forward: %{1 => "one"}, inverse: %{"one" => 1}}
      assert InvMap.update!(InvMap.new(one: 1), 1, &to_string/1) == expected
    end

    test "raises KeyError when the key is not present" do
      assert_raise KeyError, ~r/key :two not found in:/, fn ->
        InvMap.update!(InvMap.new(one: 1), :two, &to_string/1)
      end
    end

    test "raises FunctionClauseError when fun arity is not 1" do
      assert_raise FunctionClauseError, fn ->
        InvMap.update!(InvMap.new(one: 1), :one, fn -> :oops end)
      end

      assert_raise FunctionClauseError, fn ->
        InvMap.update!(InvMap.new(one: 1), :one, fn _, _ -> :oops end)
      end
    end
  end

  describe "delete/2" do
    test "deletes the entry from the forward map" do
      inv_map = InvMap.new(a: 1, b: 2)
      assert InvMap.delete(inv_map, :a) == %InvMap{forward: %{:b => 2}, inverse: %{2 => :b}}
    end

    test "deletes the entry from the inverse map" do
      inv_map = InvMap.new(a: 1, b: 2)
      assert InvMap.delete(inv_map, 1) == %InvMap{forward: %{:b => 2}, inverse: %{2 => :b}}
    end

    test "returns inv_map unchanged if the key does not exist" do
      inv_map = InvMap.new(b: 2)
      assert InvMap.delete(inv_map, :a) == %InvMap{forward: %{:b => 2}, inverse: %{2 => :b}}
    end
  end

  describe "equal?/2" do
    test "returns true for InvMaps with the same pairs" do
      assert InvMap.equal?(InvMap.new(a: 1, b: 2), InvMap.new(b: 2, a: 1)) == true
    end

    test "returns false for InvMaps with different pairs" do
      assert InvMap.equal?(InvMap.new(a: 1, b: 2), InvMap.new(b: 1, a: 2)) == false
    end

    test "returns true for InvMaps with the same pairs in different directions" do
      assert InvMap.equal?(InvMap.new(%{1 => 2}), InvMap.new(%{2 => 1})) == true
    end

    test "returns false when InvMaps differ in size (even if one is a subset)" do
      assert InvMap.equal?(InvMap.new(a: 1), InvMap.new(a: 1, b: 2)) == false
      assert InvMap.equal?(InvMap.new(a: 1, b: 2), InvMap.new(a: 1)) == false
    end

    test "returns false when one InvMap has a nil and the other is missing the key" do
      assert InvMap.equal?(InvMap.new(a: nil), InvMap.new(b: nil)) == false
    end

    test "returns false when keys and values are not strictly equal" do
      assert InvMap.equal?(InvMap.new(%{:one => 1}), InvMap.new(%{:one => 1.0})) == false
      assert InvMap.equal?(InvMap.new(%{1 => :one}), InvMap.new(%{1.0 => :one})) == false
    end
  end

  describe "has_key?/2" do
    test "returns true if the key is present in the forward map" do
      assert InvMap.has_key?(InvMap.new(a: 1), :a) == true
    end

    test "returns true if the key is present in the inverse map" do
      assert InvMap.has_key?(InvMap.new(a: 1), 1) == true
    end

    test "returns false if the key is not present" do
      assert InvMap.has_key?(InvMap.new(a: 1), :b) == false
    end
  end

  describe "to_list/1" do
    test "returns a list of tuples, one for each entry in the forward map" do
      assert InvMap.to_list(InvMap.new(%{a: 1})) == [a: 1]
      assert InvMap.to_list(InvMap.new(%{1 => 2})) == [{1, 2}]
    end
  end

  describe "filter/2" do
    test "returns an InvMap containing only pairs for which fun returns truthy" do
      inv_map = InvMap.new(one: 1, two: 2)
      expected = %InvMap{forward: %{one: 1}, inverse: %{1 => :one}}
      assert InvMap.filter(inv_map, fn {_key, val} -> rem(val, 2) == 1 end) == expected
    end

    test "raises FunctionClauseError when fun arity is not 1" do
      assert_raise FunctionClauseError, fn ->
        InvMap.filter(InvMap.new(one: 1), fn _key, _val -> true end)
      end

      assert_raise FunctionClauseError, fn ->
        InvMap.filter(InvMap.new(one: 1), fn -> true end)
      end
    end
  end

  describe "reject/2" do
    test "returns an InvMap excluding pairs for which fun returns truthy" do
      inv_map = InvMap.new(one: 1, two: 2)
      expected = %InvMap{forward: %{two: 2}, inverse: %{2 => :two}}
      assert InvMap.reject(inv_map, fn {_key, val} -> rem(val, 2) == 1 end) == expected
    end

    test "raises FunctionClauseError when fun arity is not 1" do
      assert_raise FunctionClauseError, fn ->
        InvMap.reject(InvMap.new(one: 1), fn _key, _val -> true end)
      end

      assert_raise FunctionClauseError, fn ->
        InvMap.reject(InvMap.new(one: 1), fn -> true end)
      end
    end
  end
end
