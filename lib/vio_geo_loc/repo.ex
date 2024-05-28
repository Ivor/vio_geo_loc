defmodule VioGeoLoc.Repo do
  use Ecto.Repo,
    otp_app: :vio_geo_loc,
    adapter: Ecto.Adapters.Postgres
end
