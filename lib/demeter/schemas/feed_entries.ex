defmodule Demeter.FeedEntry do
  use Ecto.Schema

  # Migrations are stored on the node js server
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "feed_entries" do
    field(:guid, :string)

    timestamps(
      inserted_at_source: :created_at,
      updated_at_source: :updated_at
    )
  end

  def changeset(%Demeter.FeedEntry{} = entry, params \\ %{}) do
    entry
    |> Ecto.Changeset.cast(params, [
      :guid
    ])
    |> Ecto.Changeset.validate_required([:guid])
  end
end
