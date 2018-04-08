defmodule ElixirDrip.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:id, ElixirDrip.Ecto.Ksuid, autogenerate: true}
  schema "users" do
    field :username, :string
    field :hashed_password, :string
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def create_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> validate_length(:username, min: 1, max: 30)
    |> validate_length(:password, min: 8, max: 100)
    |> unique_constraint(:username)
    |> put_hashed_password()
  end

  defp put_hashed_password(%Ecto.Changeset{valid?: false} = changeset), do: changeset
  defp put_hashed_password(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = changeset) do
    changeset
    |> put_change(:hashed_password, Comeonin.Bcrypt.hashpwsalt(pw))
  end
end
