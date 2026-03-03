defmodule InvMapTest do
  use ExUnit.Case
  doctest InvMap

  describe "new/0" do
    test "returns a new empty InvMap" do
      assert InvMap.new() == %InvMap{forward: %{}, inverse: %{}}
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
end
