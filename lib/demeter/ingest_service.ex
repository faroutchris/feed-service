defmodule Demeter.IngestService do
  @moduledoc """
  The `Demeter.IngestService` module is responsible for managing the ingestion and updating of feed data.
  It utilizes concurrency to efficiently handle multiple feeds, updating them concurrently.

  ## Functions

    - `update_feeds/0`: Fetches and updates all feeds that are due for an update.
    - `save_feed/1`: Saves the changeset of a feed to the database.
    - `update_pipeline/1`: Orchestrates the fetching, parsing, and updating of a single feed source.
    - `get_favicon/0`: Placeholder function for retrieving favicons (TODO).

  ## Private Functions

    - `get_in_safe/3`: Safely retrieves a nested value from a map, returning a default if not found.
    - `map_entry/1`: Maps an entry from the feed data to a structured format.
    - `update_feed_data/4`: Updates feed data with new entries and prepares a changeset.
    - `get_feed/1`: Fetches the feed data using an external worker.
    - `parse_feed/1`: Parses the feed data from a fetched HTTP response.
    - `extract_header/2`: Extracts a specific header from an HTTP response.
    - `calculate_next/1`: Calculates the next fetch time for a feed.

  ## Configuration

  The module uses two configuration settings for timeouts:

    - `@http_timeout`: Timeout for HTTP requests, set to 30,000 milliseconds (30 seconds).
    - `@parse_timeout`: Timeout for parsing feed data, set to 30,000 milliseconds (30 seconds).

  ## Example Usage

      iex> Demeter.IngestService.update_feeds()
      :ok

  This function fetches all feeds, updates them concurrently, and saves them to the database.

  """
  import Ecto.Query, warn: false
  alias Demeter.Feed
  alias Demeter.Repo.Feeds
  alias Demeter.FetchWorker
  alias Demeter.HttpUtils

  @http_timeout 30_000
  @parse_timeout 30_000

  def update_feeds do
    Feeds.list(:due_for_update)
    |> Stream.map(&Task.async(fn -> update_pipeline(&1) end))
    |> Stream.map(&Task.await(&1))
    |> Enum.to_list()
  end

  def save_feed(changeset) do
    changeset |> Feeds.update()
  end

  def update_pipeline(feed_source) do
    with {:ok, %Feed{} = feed_source, %HTTPoison.Response{} = response} <- get_feed(feed_source),
         {:ok, %{feed: feed, entries: entries}} <- parse_feed(response),
         {:ok, %Ecto.Changeset{} = changeset} <- update_feed_data(feed_source, feed, entries, response) do
      # refactor to return the changeset to the worker
      save_feed(changeset)
    else
      # Here we need to renew the last_updated timestamp
      {:not_modified, %Feed{} = feed} -> IO.puts("#{feed.url} has not been modified")
      error -> error
    end
  end

  defp get_in_safe(data, keys, default \\ nil) do
    case get_in(data, keys) do
      nil -> default
      result -> result
    end
  end

  # Move to ecto
  defp map_entry(gluttony_entry) do
    IO.inspect(
      %{
        # common
        title: Map.get(gluttony_entry, :title),
        source: Map.get(gluttony_entry, :source),
        link: Map.get(gluttony_entry, :link),
        links: Map.get(gluttony_entry, :links),
        description: Map.get(gluttony_entry, :description),
        comments: Map.get(gluttony_entry, :comments),
        guid: Map.get(gluttony_entry, :guid, Map.get(gluttony_entry, :link)),
        enclosure_type: get_in_safe(gluttony_entry, [:enclosure, :type]),
        enclosure_length: get_in_safe(gluttony_entry, [:enclosure, :length]),
        enclosure_url: get_in_safe(gluttony_entry, [:enclosure, :url]),
        # rss2
        pub_date: Map.get(gluttony_entry, :pub_date),
        # atom
        atom_published: Map.get(gluttony_entry, :pub_date),
        atom_updated: Map.get(gluttony_entry, :updated),
        atom_summary: Map.get(gluttony_entry, :summary),
        atom_content: Map.get(gluttony_entry, :content),
        atom_contributors: Map.get(gluttony_entry, :content),
        atom_rights: Map.get(gluttony_entry, :rights),
        # atom_author_name: get_in_safe(gluttony_entry, [:author, :name]),
        # atom_author_email: get_in_safe(gluttony_entry, [:author, :email]),
        # atom_author_uri: get_in_safe(gluttony_entry, [:author, :uri]),
        # # merge atom_source_id with guid?
        # atom_source_id: get_in_safe(gluttony_entry, [:source, :id]),
        # itunes/google
        itunes_title: Map.get(gluttony_entry, :itunes_title),
        itunes_explicit: Map.get(gluttony_entry, :itunes_explicit),
        itunes_episode_type: Map.get(gluttony_entry, :itunes_episode_type),
        itunes_duration: Map.get(gluttony_entry, :itunes_duration),
        googleplay_image: Map.get(gluttony_entry, :googleplay_image),
        googleplay_author: Map.get(gluttony_entry, :googleplay_author),
        googleplay_description: Map.get(gluttony_entry, :googleplay_description)
      },
      label: "--->"
    )
  end

  defp update_feed_data(%Feed{} = feed_source, gluttony_feed, gluttony_entries, %HTTPoison.Response{} = response) do
    # IO.inspect(gluttony_entries, label: "--->")
    Enum.map(gluttony_entries, fn entry -> map_entry(entry) end)

    changeset =
      feed_source
      |> Demeter.Feed.changeset(%{
        title: Map.get(gluttony_feed, :title),
        description: Map.get(gluttony_feed, :description),
        etag: HttpUtils.extract_header("etag", response),
        last_modified: HttpUtils.extract_header("last-modified", response),
        next_fetch: calculate_next(response),
        updated: Map.get(gluttony_feed, :updated),
        authors: Map.get(gluttony_feed, :author),
        categories: Map.get(gluttony_feed, :category),
        copyright: Map.get(gluttony_feed, :copyright),
        icon: Map.get(gluttony_feed, :icon),
        logo: Map.get(gluttony_feed, :logo),
        links: Map.get(gluttony_feed, :link),
        language: Map.get(gluttony_feed, :language)
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
    Task.Supervisor.async_nolink(Demeter.TaskSupervisor, fn ->
      Gluttony.parse_string(response.body)
    end)
    |> Task.await(@parse_timeout)
  end

  defp calculate_next(%HTTPoison.Response{} = _response) do
    # TODO
    DateTime.utc_now()
    |> DateTime.add(6, :hour)
  end
end
