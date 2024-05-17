defmodule Demeter.Repo.FeedSources do
  import Ecto.Query, warn: false
  alias Demeter.Repo.FeedSources
  alias Demeter.FeedSources
  alias Demeter.Repo

  @time_limit 60 * 60

  def list do
    Repo.all(FeedSources)
  end

  def list(:due_for_update) do
    {:ok, now} = DateTime.now("Etc/UTC")
    overdue = DateTime.add(now, -@time_limit)

    from(
      feed_sources in FeedSources,
      where: feed_sources.updated_at < ^overdue,
      select: feed_sources
    )
    |> Repo.all()
  end

  def create(%FeedSources{} = feed_source, attrs \\ %{}) do
    feed_source
    |> FeedSources.changeset(attrs)
    |> Repo.insert()
  end
end
