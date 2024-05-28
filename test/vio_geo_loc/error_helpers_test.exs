defmodule VioGeoLoc.ErrorHelpersTest do
  use VioGeoLoc.DataCase

  alias VioGeoLoc.GeoLocation

  describe "translate_errors/1" do
    test "translates changeset errors for missing fields" do
      changeset = GeoLocation.changeset(%GeoLocation{}, %{})

      assert %{
               country: ["Country can't be blank"],
               country_code: ["Country code can't be blank"],
               ip_address: ["Ip address can't be blank"],
               latitude: ["Latitude can't be blank"],
               longitude: ["Longitude can't be blank"]
             } = VioGeoLoc.ErrorHelpers.translate_errors(changeset)
    end

    test "translate changeset errors for invalid values" do
      changeset =
        GeoLocation.changeset(%GeoLocation{}, %{
          ip_address: "1.1.1",
          longitude: 200.0,
          latitude: 100.0
        })

      assert %{
               ip_address: ["Ip address is not a valid IPv4 address"],
               latitude: ["Latitude must be less than or equal to 90"],
               longitude: ["Longitude must be less than or equal to 180"]
             } = VioGeoLoc.ErrorHelpers.translate_errors(changeset)
    end
  end
end
