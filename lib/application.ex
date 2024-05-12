defmodule Demeter.Application do
  use Application

  def start(_type, _args) do
    IO.puts("Starting the application")

    Demeter.Supervisor.start_link()
  end
end
