defmodule VioGeoLocWeb.GeoLocationJSON do
  alias GeoLocService.GeoLocation

  @doc """
  Renders a single geo_location.
  """
  def show(%{geo_location: geo_location}) do
    %{data: data(geo_location)}
  end

  defp data(%GeoLocation{} = geo_location) do
    %{
      type: "geo_location",
      id: geo_location.id,
      attributes: %{
        ip_address: geo_location.ip_address,
        country_code: geo_location.country_code,
        country: geo_location.country,
        city: geo_location.city,
        latitude: geo_location.latitude,
        longitude: geo_location.longitude,
        mystery_value: geo_location.mystery_value
      }
    }
  end
end
