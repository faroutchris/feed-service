defmodule Demeter.Repo.Feeds do
  import Ecto.Query, warn: false
  alias Demeter.Feed
  alias Demeter.Repo

  # @time_limit 60 * 60
  @time_limit 60 * 60

  def list do
    Repo.all(Feed)
  end

  def list(:due_for_update) do
    {:ok, now} = DateTime.now("Etc/UTC")
    overdue = DateTime.add(now, -@time_limit, :second)

    from(
      feed_sources in Feed,
      where: feed_sources.updated_at < ^overdue,
      select: feed_sources
    )
    |> Repo.all()
  end

  def create(%Feed{} = feed_source, attrs \\ %{}) do
    feed_source
    |> Feed.changeset(attrs)
    |> Repo.insert()
  end

  def update(changeset) do
    changeset |> Repo.insert_or_update()
  end
end
