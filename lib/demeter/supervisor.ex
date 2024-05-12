defmodule Demeter.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      # Start the ecto repo
      Demeter.Repo,
      # Start the scheduler
      Demeter.Scheduler
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
