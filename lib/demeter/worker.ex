defmodule Demeter.Worker do
  def spawn(feeds, pid) do
    feeds |> Enum.each(fn feed -> spawn(__MODULE__, :get, [feed, pid]) end)
  end

  def get(feed, pid) do
    send(pid, {:ok, feed.url})
  end
end
