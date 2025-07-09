defmodule AdminApiTest do
  use ExUnit.Case
  doctest AdminApi

  test "greets the world" do
    assert AdminApi.hello() == :world
  end
end
