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
  end

  describe "put/3" do
    test "puts the key value pair in inv_map" do
      assert InvMap.put(InvMap.new(), :a, 1) == %InvMap{forward: %{:a => 1}, inverse: %{1 => :a}}
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
end
