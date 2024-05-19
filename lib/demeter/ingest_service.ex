defmodule Demeter.IngestService do
  import Ecto.Query, warn: false
  alias Demeter.Feed
  alias Demeter.Repo.Feeds
  alias Demeter.FetchWorker

  @http_timeout 30_000
  @parse_timeout 30_000

  def update_feeds do
    Feeds.list(:due_for_update)
    |> Stream.map(&update_pipeline/1)
    |> Enum.to_list()

    # Current implementation saves each feed into db
    # refactor to return a collection and run a ecto.multi transaction
  end

  def save_feed(changeset) do
    changeset |> Feeds.update()
  end

  def update_pipeline(feed_source) do
    with {:ok, %Feed{} = feed_source, %HTTPoison.Response{} = response} <-
           get_feed(feed_source),
         {:ok, feed} <-
           parse_feed(response),
         {:ok, %Ecto.Changeset{} = changeset} <-
           update_feed_data(feed_source, feed, response) do
      save_feed(changeset)
    else
      error -> error
    end
  end

  defp update_feed_data(
         %Feed{} = feed_source,
         %Gluttony.Feed{} = parsed_feed,
         %HTTPoison.Response{} = response
       ) do
    changeset =
      feed_source
      |> Demeter.Feed.changeset(%{
        title: parsed_feed.title,
        etag: extract_header("etag", response),
        last_modified: extract_header("last-modified", response),
        next_fetch: calculate_next(response)
      })

    {:ok, changeset}
  end

  defp get_feed(%Feed{} = feed_source) do
    Task.Supervisor.async_nolink(Demeter.TaskSupervisor, fn ->
      FetchWorker.fetch_feed(feed_source)
    end)
    |> Task.await(@http_timeout)
  end

  defp parse_feed(%HTTPoison.Response{} = response) do
    {:ok, %{feed: feed, entries: _entries}} =
      Task.Supervisor.async_nolink(Demeter.TaskSupervisor, fn ->
        Gluttony.parse_string(response.body)
      end)
      |> Task.await(@parse_timeout)

    {:ok, feed}
  end

  def get_favicon do
    # TODO
    # {:ok, favicon}
    # {:continue, nil}
  end

  # Create a HTTPUtils module
  defp extract_header(header_name, %HTTPoison.Response{} = response) do
    yo =
      Enum.map(response.headers, fn {header, value} ->
        {String.downcase(header, :default), value}
      end)
      |> Enum.into(%{})
      |> Map.get(header_name)

    IO.inspect(yo, label: header_name)
  end

  defp calculate_next(%HTTPoison.Response{} = _response) do
    # TODO
    DateTime.utc_now()
    |> DateTime.add(6, :hour)
  end
end
