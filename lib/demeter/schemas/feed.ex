defmodule Demeter.Feed do
  use Ecto.Schema

  # Migrations are stored on the node js server
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "feeds" do
    field(:url, :string)
    field(:etag, :string)
    field(:last_modified, :string)
    field(:next_fetch, :naive_datetime)
    field(:title, :string)
    field(:description, :string)
    field(:links, :string)
    field(:updated, :string)
    field(:authors, :string)
    field(:contributors, :string)
    field(:language, :string)
    field(:icon, :string)
    field(:logo, :string)
    field(:copyright, :string)

    timestamps(
      inserted_at_source: :created_at,
      updated_at_source: :updated_at
    )
  end

  def changeset(%Demeter.Feed{} = feed_source, params \\ %{}) do
    feed_source
    |> Ecto.Changeset.cast(params, [
      :url,
      :etag,
      :last_modified,
      :next_fetch,
      :title,
      :url,
      :description
    ])
    |> Ecto.Changeset.validate_required([:url, :title, :description])
  end
end
