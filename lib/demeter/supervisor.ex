defmodule Demeter.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      # Start the ecto repo
      Demeter.Repo,
      # Start the task supervisor
      {Task.Supervisor, name: Demeter.TaskSupervisor},
      # Start the scheduler
      Demeter.Scheduler
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
