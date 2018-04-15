defmodule ElixirDrip.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias ElixirDrip.Repo
  alias ElixirDrip.Accounts.User

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end


  def find_user(user_id) do
    User
    |> Repo.get(user_id)
  end

  def login_user_with_pw(username, password) do
    with %User{} = user <- get_user_by_username(username),
         true <- verify_user_password(user, password) do
      {:ok, user}
    else
      _ ->
        Comeonin.Bcrypt.dummy_checkpw()
        :error
    end
  end

  def get_user_by_username(username) do
    User
    |> Repo.get_by(username: username)
  end

  defp verify_user_password(%User{} = user, password) do
    Comeonin.Bcrypt.checkpw(password, user.hashed_password)
  end
end
