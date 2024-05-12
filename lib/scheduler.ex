defmodule Demeter.Scheduler do
  use GenServer

  # 5 seconds
  @interval 5 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    run_scheduled_task()

    schedule_next_update()

    {:ok, state}
  end

  def schedule_next_update do
    IO.puts("Scheduled next work update in #{@interval} ms")
    Process.send_after(self(), :update, @interval)
  end

  def run_scheduled_task do
    feeds = [%{url: "http://www.google.com"}, %{url: "http://www.google2.com"}]

    Demeter.Worker.spawn(feeds, self())
  end

  def handle_info(:update, state) do
    run_scheduled_task()

    schedule_next_update()

    {:noreply, state}
  end

  def handle_info({:ok, feed_url}, state) do
    IO.puts("spawned worker and returned ok with #{feed_url}")

    {:noreply, state}
  end
end
