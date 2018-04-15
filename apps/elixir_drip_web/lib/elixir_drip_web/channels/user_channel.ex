defmodule ElixirDripWeb.UserChannel do
  use ElixirDripWeb, :channel

  def join("users:" <> _user_id, auth_message, socket) do
    # :timer.send_interval(5_000, :ping)

    # {:ok, assign(socket, :user_id, user_id)}
    {:ok, socket}
  end

  # def handle_info(:ping, socket) do
  #   count = socket.assigns[:count] || 1
  #   push(socket, "ping", %{count: count})

  #   {:noreply, assign(socket, :count, count + 1)}
  # end
end
