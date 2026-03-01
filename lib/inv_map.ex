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
end
