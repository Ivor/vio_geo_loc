defmodule VioGeoLocWeb.GeoLocationControllerTest do
  use VioGeoLocWeb.ConnCase

  alias GeoLocService.GeoLocations

  setup %{conn: conn} do
    attrs = %{
      ip_address: "1.1.1.1",
      country_code: "AU",
      country: "Australia",
      city: "Sydney",
      latitude: "33.8688",
      longitude: "151.2093",
      mystery_value: 42
    }

    {:ok, geo_location} = GeoLocations.create_geo_location(attrs, repo: VioGeoLoc.Repo)

    {:ok, conn: put_req_header(conn, "accept", "application/json"), geo_location: geo_location}
  end

  describe "GET show geo_location" do
    test "renders geo_location when the IP address is in our database", %{
      conn: conn,
      geo_location: geo_location
    } do
      conn = get(conn, ~p"/api/geo_locations/#{geo_location.ip_address}")

      json_geo_location_data = json_response(conn, 200)["data"]

      assert "geo_location" = json_geo_location_data["type"]
      assert geo_location.id == json_geo_location_data["id"]
      assert geo_location.ip_address == json_geo_location_data["attributes"]["ip_address"]
      assert geo_location.country_code == json_geo_location_data["attributes"]["country_code"]
      assert geo_location.country == json_geo_location_data["attributes"]["country"]
      assert geo_location.city == json_geo_location_data["attributes"]["city"]

      assert Decimal.compare(
               geo_location.latitude,
               Decimal.new(json_geo_location_data["attributes"]["latitude"])
             )

      assert Decimal.compare(
               geo_location.longitude,
               Decimal.new(json_geo_location_data["attributes"]["longitude"])
             )

      assert geo_location.mystery_value == json_geo_location_data["attributes"]["mystery_value"]
    end

    test "returns 404 when the IP address is not in our database", %{conn: conn} do
      conn = get(conn, ~p"/api/geo_locations/2.2.2.2")
      assert json_response(conn, 404)["errors"] == %{"detail" => "Not Found"}
    end
  end
end
