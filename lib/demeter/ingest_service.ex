defmodule Demeter.IngestService do
  alias Demeter.FetchWorker
  alias Demeter.Repo.FeedSourcesRepo
  alias Demeter.FeedSources

  @timeout 10_000

  def update_feeds do
    FeedSourcesRepo.list(:due_for_update)
    |> Enum.map(&update_pipeline/1)
  end

  def update_pipeline(feed_source) do
    with {:ok, %FeedSources{} = feed_source, %HTTPoison.Response{} = response} <-
           get_feed(feed_source),
         {:ok, %Ecto.Changeset{} = changeset, %HTTPoison.Response{} = response} <-
           update_feed_source({feed_source, response}) do
      IO.inspect(changeset, label: "feed_source -->")
      IO.inspect(response, label: "response -->")
    end
  end

  defp update_feed_source({%FeedSources{} = feed_source, %HTTPoison.Response{} = response}) do
    changeset =
      feed_source
      |> Demeter.FeedSources.changeset(%{
        etag: extract_header("ETag", response),
        last_modified: extract_header("Last-Modified", response)
      })

    {:ok, changeset, response}
  end

  def get_feed(feed_source) do
    Task.Supervisor.async_nolink(Demeter.TaskSupervisor, fn ->
      FetchWorker.fetch_feed(feed_source)
    end)
    |> Task.await(@timeout)
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

  # Create a HTTPUtils module
  defp extract_header(header_name, %HTTPoison.Response{} = response) do
    enum_headers = Enum.into(response.headers, %{})
    enum_headers[header_name]
  end
end
