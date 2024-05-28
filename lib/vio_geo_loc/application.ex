defmodule VioGeoLoc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VioGeoLocWeb.Telemetry,
      VioGeoLoc.Repo,
      {DNSCluster, query: Application.get_env(:vio_geo_loc, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VioGeoLoc.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: VioGeoLoc.Finch},
      # Start a worker by calling: VioGeoLoc.Worker.start_link(arg)
      # {VioGeoLoc.Worker, arg},
      # Start to serve requests, typically the last entry
      VioGeoLocWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VioGeoLoc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VioGeoLocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
