import "phoenix_html"
import socket from "./socket"

import Notification from "./notification"
import OnlineUsers from "./online_users"

Notification.init(socket, window.userId)
OnlineUsers.init(socket)
