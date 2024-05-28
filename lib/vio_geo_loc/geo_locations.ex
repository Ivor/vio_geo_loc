defmodule VioGeoLoc.GeoLocations do
  alias VioGeoLoc.Repo
  alias VioGeoLoc.GeoLocation
  alias VioGeoLoc.ImportServer

  def import(source, error_file_path \\ "./errors.txt") do
    with {:ok, _pid} <- ImportServer.start_link(source: source, error_file_path: error_file_path) do
      {:ok, "Import started."}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def create_geo_location(attrs) do
    %GeoLocation{}
    |> GeoLocation.changeset(attrs)
    |> Repo.insert()
  end

  # TODO: query by IP adddress for the JSON API.
end
