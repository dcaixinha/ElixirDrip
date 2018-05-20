defmodule ElixirDripWeb.PageControllerTest do
  use ElixirDripWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to ElixirDrip v0.0.8!"
  end
end
