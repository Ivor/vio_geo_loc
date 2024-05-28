defmodule VioGeoLoc.Repo.Migrations.CreateGeoLocations do
  use Ecto.Migration

  def change do
    create table(:geo_locations) do
      add :ip_address, :string
      add :country_code, :string
      add :country, :string
      add :city, :string
      add :latitude, :decimal, precision: 15, scale: 13
      add :longitude, :decimal, precision: 16, scale: 13
      add :mystery_value, :bigint

      timestamps(type: :utc_datetime)
    end

    create index(:geo_locations, [:ip_address], unique: true)
  end
end
