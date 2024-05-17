defmodule Demeter.FeedSources do
  use Ecto.Schema

  # Migrations are stored on the node js server
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "feed_sources" do
    field(:url, :string)
    # Metadata
    field(:etag, :string)
    field(:last_modified, :string)
    field(:next_fetch, :naive_datetime)
    # Feederex fields

    timestamps(
      inserted_at_source: :created_at,
      updated_at_source: :updated_at
    )
  end

  def changeset(feed_source, params \\ %{}) do
    feed_source
    |> Ecto.Changeset.cast(params, [:url, :etag, :last_modified, :next_fetch])
    |> Ecto.Changeset.validate_required([:url])
  end
end
