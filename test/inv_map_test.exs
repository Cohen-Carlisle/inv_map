defmodule InvMapTest do
  use ExUnit.Case
  doctest InvMap

  describe "new/0" do
    test "returns a new empty InvMap" do
      assert InvMap.new() == %InvMap{forward: %{}, inverse: %{}}
    end
  end
end
