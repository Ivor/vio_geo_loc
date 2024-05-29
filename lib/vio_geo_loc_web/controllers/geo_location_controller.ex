defmodule VioGeoLocWeb.GeoLocationController do
  use VioGeoLocWeb, :controller

  action_fallback VioGeoLocWeb.FallbackController

  def show(conn, %{"ip_address" => ip_address}) do
    with {:ok, geo_location} <- GeoLocService.fetch_geo_location(ip_address) do
      render(conn, :show, geo_location: geo_location)
    end
  end
end
