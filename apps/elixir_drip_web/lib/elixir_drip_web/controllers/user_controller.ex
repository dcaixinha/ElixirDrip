defmodule ElixirDripWeb.UserController do
  use ElixirDripWeb, :controller

  alias ElixirDrip.Accounts
  alias ElixirDripWeb.Plugs.Auth

  def new(conn, _params) do
    render(conn, "new.html", changeset: Accounts.User.create_changeset(%Accounts.User{}))
  end

  def create(conn, %{"user" => user_params}) do
    #TODO Change this to `with`before commit
    case Accounts.create_user(user_params) do
      {:ok, changeset} ->
        conn
        |> Auth.login(changeset)
        |> put_flash(:info, "Your account was created!")
        |> redirect(to: file_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Unable to create account. Please check the errors below.")
        |> render("new.html", changeset: changeset)
    end
  end
end
