defmodule VioGeoLoc.GeoLocation do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "geo_locations" do
    field :ip_address, :string
    field :country_code, :string
    field :country, :string
    field :city, :string
    field :latitude, :decimal
    field :longitude, :decimal
    field :mystery_value, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(geo_location, attrs) do
    geo_location
    |> cast(attrs, [
      :ip_address,
      :country_code,
      :country,
      :city,
      :latitude,
      :longitude,
      :mystery_value
    ])
    |> validate_required([:ip_address, :country_code, :country, :latitude, :longitude])
    |> validate_format(
      :ip_address,
      ~r/^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/,
      message: "is not a valid IPv4 address"
    )
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> unique_constraint(:ip_address, name: :geo_locations_ip_address_index)
  end
end
