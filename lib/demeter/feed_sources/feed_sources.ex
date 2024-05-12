defmodule Demeter.FeedSources do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "feed_sources" do
    field(:url, :string)
    # Metadata
    field(:etag, :string)
    field(:last_modified, :string)
    # Feederex fields

    timestamps()
  end
end
