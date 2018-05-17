let Notification = {
  init(socket, userId) {
    let infoArea = document.getElementById("notify_info")
    let successArea = document.getElementById("notify_success")
    let userChannel = socket.channel("users:" + userId)

    userChannel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", reason => { console.log("Unable to join", reason) })

    userChannel.on("upload", ({message}) => this.renderUploadNotifcation(infoArea, successArea, message))
    userChannel.on("download", ({message, link}) => this.renderDownloadNotifcation(infoArea, successArea, message, link))
  },

  renderUploadNotifcation(infoArea, successArea, message) {
    infoArea.innerHTML = ""
    successArea.innerHTML = message
  },

  renderDownloadNotifcation(infoArea, successArea, message, link) {
    infoArea.innerHTML = ""
    successArea.innerHTML = `<a href="${link}">${message}</a>`
  }
}

export default Notification
