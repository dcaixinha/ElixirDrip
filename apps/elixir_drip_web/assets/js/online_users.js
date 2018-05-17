import {Presence} from "phoenix"

let OnlineUsers = {
  init(socket) {
    let lobbyChannel = socket.channel("users:lobby")
    let presences = {}

    lobbyChannel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", reason => { console.log("Unable to join", reason) })

    lobbyChannel.on("presence_state", state => {
      presences = Presence.syncState(presences, state)
      this.renderOnlineUsers(presences)
    })

    lobbyChannel.on("presence_diff", diff => {
      presences = Presence.syncDiff(presences, diff)
      this.renderOnlineUsers(presences)
    })
  },

  renderOnlineUsers(presences) {
    let response = ""

    Presence.list(presences, (id, {metas: [user, ...rest]}) => {
      let count = rest.length + 1
      response += `<li>${user.username} (count: ${count})</li>`
    })

    document.getElementById("online_users").innerHTML = `<ul>${response}</ul>`
  }
}

export default OnlineUsers
