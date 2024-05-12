defmodule DemeterTest do
  use ExUnit.Case
  doctest Demeter

  test "greets the world" do
    assert Demeter.hello() == :world
  end
end
