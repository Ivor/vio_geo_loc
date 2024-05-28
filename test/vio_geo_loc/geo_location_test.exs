defmodule VioGeoLoc.GeoLocationTest do
  use VioGeoLoc.DataCase

  alias VioGeoLoc.GeoLocation

  #   ip_address,country_code,country,city,latitude,longitude,mystery_value
  # 200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
  # 160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
  # 70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
  # ,PY,Falkland Islands (Malvinas),,75.41685191518815,-144.6943217219469,0
  # 125.159.20.54,LI,Guyana,Port Karson,-78.2274228596799,-163.26218895343357,1337885276

  @valid_attrs %{
    ip_address: "1.1.1.1",
    country_code: "AU",
    country: "Australia",
    city: "Sydney",
    latitude: 33.8688,
    longitude: 151.2093,
    mystery_value: 1_234_567_890
  }

  describe "changeset/2" do
    test "changeset with valid data" do
      changeset = GeoLocation.changeset(%GeoLocation{}, @valid_attrs)

      assert changeset.valid?
    end

    test "validates that the ip address is a valid IPv4 address" do
      attrs = Map.put(@valid_attrs, :ip_address, "1.1.1")

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert {"is not a valid IPv4 address", [validation: :format]} =
               changeset.errors[:ip_address]
    end

    test "is valid if the data is good but the mystery value is not present" do
      attrs = Map.delete(@valid_attrs, :mystery_value)

      changeset = GeoLocation.changeset(%GeoLocation{}, attrs)

      assert changeset.valid?
    end

    test "validates that the rest of the fields are required" do
      [:ip_address, :country_code, :country, :latitude, :longitude]
      |> Enum.each(fn field ->
        attrs = Map.delete(@valid_attrs, field)

        changeset = GeoLocation.changeset(%GeoLocation{}, attrs)
        assert {"can't be blank", [validation: :required]} = changeset.errors[field]
      end)
    end
  end
end
