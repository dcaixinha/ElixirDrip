defmodule ElixirDripWeb.UserChannel do
  use ElixirDripWeb, :channel
  alias ElixirDripWeb.Presence

  def join("users:lobby", _auth_message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("users:" <> _user_id, _auth_message, socket) do
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    user = Accounts.find_user(socket.assigns.user_id)

    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        username: user.username
      })

    {:noreply, socket}
  end

end
