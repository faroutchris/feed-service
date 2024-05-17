defmodule Demeter.FeedService do
  alias Demeter.FetcherWorker
  alias Demeter.Repo.FeedSources

  def update_feeds do
    FeedSources.list(:due_for_update)
    |> Enum.map(fn feed_source ->
      Task.Supervisor.async_nolink(Demeter.TaskSupervisor, fn ->
        FetcherWorker.fetch_feed(feed_source)
      end)
    end)
    |> Enum.map(&Task.await/1)
    |> IO.inspect(label: "-->")
  end

  def parse_feed do
    # parse xml data
    # {:ok, Gluttony.Feed}
    # {:error, reason}
  end

  def extract_meta_data do
    # parse etag and last-modified
    # {:ok, headers}
    # {:continue, nil}
  end

  def get_favicon do
    # {:ok, favicon}
    # {:continue, nil}
  end

  def save_feed do
    # Call FeedSources repo
  end
end
