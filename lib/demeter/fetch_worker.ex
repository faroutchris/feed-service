defmodule Demeter.FetchWorker do
  @moduledoc """
  A module responsible for fetching and verifying updates for feed sources.

  This module performs the following tasks:

  - Takes a feed source struct (`%FeedSources{}`).
  - Makes an HTTP GET request with cache headers if they exist.

  ## Responses:

  - **200 OK**:
    - Checks if the response headers match the cached headers to verify if the feed has been updated.
    - Returns `{:ok, feed_source, response}` if the feed has been updated.
    - Returns `{:not_modified, feed_source}` if the feed has not been updated.
  - **304 Not Modified**:
    - Returns `{:not_modified, feed_source}` indicating the feed has not changed.
  - **Error**:
    - Returns `{:error, reason}` indicating an error occurred during the request.

  ## Example:
      iex> Demeter.FetcherWorker.fetch_feed(feed_source)
      {:ok, feed_source, %HTTPoison.Response{...}}
  """

  alias Demeter.Feed
  alias Demeter.HttpUtils

  def fetch_feed(%Feed{} = feed_source) do
    IO.inspect(feed_source.url)

    headers =
      %{}
      |> HttpUtils.make_headers("If-Modified-Since", feed_source.last_modified)
      |> HttpUtils.make_headers("If-None-Match", feed_source.etag)

    with {:ok, response} <- HTTPoison.get(feed_source.url, headers),
         :modified <- check_is_modified(response, feed_source) do
      {:ok, feed_source, response}
    else
      :not_modified -> {:not_modified, feed_source}
      {:error, error} -> {:error, error}
    end
  end

  defp check_is_modified(%HTTPoison.Response{} = response, %Feed{} = feed_source) do
    response_etag = HttpUtils.extract_header("etag", response)
    response_last_modified = HttpUtils.extract_header("last-modified", response)

    cond do
      response.status_code == 304 -> :not_modified
      HttpUtils.matching_headers?(response_last_modified, feed_source.last_modified) -> :not_modified
      HttpUtils.matching_headers?(response_etag, feed_source.etag) -> :not_modified
      true -> :modified
    end
  end
end
