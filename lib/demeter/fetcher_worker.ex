defmodule Demeter.FetcherWorker do
  alias Demeter.FeedSources

  def fetch_feed(%FeedSources{} = feed_source) do
    IO.inspect(feed_source.url)

    headers =
      %{}
      |> make_headers("If-Modified-Since", feed_source.last_modified)
      |> make_headers("If-None-Match", feed_source.etag)

    with {:ok, response} <-
           HTTPoison.get(feed_source.url, headers),
         :modified <- check_is_modified(response, feed_source) do
      {:ok, feed_source, response}
    else
      :not_modified -> {:not_modified, feed_source}
      {:error, error} -> {:error, error}
    end
  end

  defp check_is_modified(%HTTPoison.Response{} = response, %FeedSources{} = feed_source) do
    response_etag = extract_header("ETag", response)
    response_last_modified = extract_header("Last-Modified", response)

    cond do
      response.status_code == 304 -> :not_modified
      matching_headers?(response_last_modified, feed_source.last_modified) -> :not_modified
      matching_headers?(response_etag, feed_source.etag) -> :not_modified
      true -> :modified
    end
  end

  defp matching_headers?(header, value) do
    not is_nil(value) and header == value
  end

  defp make_headers(%{} = headers, name, value) do
    if value != nil do
      Map.put(headers, name, value)
    else
      headers
    end
  end

  defp extract_header(header_name, %HTTPoison.Response{} = response) do
    enum_headers = Enum.into(response.headers, %{})
    enum_headers[header_name]
  end
end
