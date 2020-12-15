const googleFormsUrl = ""
const slackWebHookUrl = ""
const username = "STNS Google Forms Notification"

const sendToSlack = (text) => {
  const data = { username: username, text: text }
  const payload = JSON.stringify(data)
  const options = {
    method: "POST",
    contentType: "application/json",
    payload: payload,
  }
  UrlFetchApp.fetch(slackWebHookUrl, options)
}

const onFormSubmit = (e) => {
  const itemResponse = e.response.getItemResponses()
  const formData = itemResponse[0]
  const name = formData.getResponse()
  sendToSlack(`${name} created a new request: ${googleFormsUrl}`)
}
