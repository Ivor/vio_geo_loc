defmodule VioGeoLoc.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  import Ecto.Changeset

  @doc """
  Translates the errors into a human-readable line along with the index of the import.
  """
  def full_error_string(changeset) do
    translate_errors(changeset)
    |> Map.values()
    |> Enum.join(". ")
  end

  @doc """
  Traverses changeset errors and translates them using the given translator function.
  """
  def translate_errors(changeset) do
    # traverse_errors(changeset, fn {msg, opts} = error ->
    traverse_errors(changeset, fn _changeset, key, error ->
      # This function translates the error message based on opts
      translate_error(key, error, get_field(changeset, key))
    end)
  end

  @doc """
  Translates an individual error message.

  Example response:
  "City can't be blank"
  """
  def translate_error(key, {msg, opts}, field_value) do
    interpolated_msg =
      opts
      |> Enum.reduce(msg, fn {key, opt_value}, acc ->
        acc
        |> String.replace("%{#{key}}", to_string(opt_value))
      end)

    field_name = Phoenix.Naming.humanize(Atom.to_string(key))

    [field_name, interpolated_msg, "(Value: #{inspect(field_value)})."]
    |> Enum.join(" ")
  end
end
