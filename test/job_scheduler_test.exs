defmodule JobSchedulerTest do
  use ExUnit.Case
  doctest JobScheduler

  test "greets the world" do
    assert JobScheduler.hello() == :world
  end
end
