import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { installDom } from "./support/dom.mjs"

installDom()

const { Application } = await import("@hotwired/stimulus")
const { default: PreviewController } = await import("../../app/javascript/controllers/twilight_struggle_preview_controller.js")

const application = Application.start()
application.register("twilight-struggle-preview", PreviewController)

const KINDS = ["win", "tie", "video"]

async function connect({ picked, inherited }) {
  const kinds = KINDS.map(
    (kind) => `
      <textarea data-twilight-struggle-preview-target="${kind}Template" data-default="">${kind === "win" ? "{usa_player}" : ""}</textarea>
      <div data-twilight-struggle-preview-target="${kind}Output"></div>
      <button data-twilight-struggle-preview-target="${kind}Reset"></button>`
  )
  document.body.innerHTML = `
    <div data-controller="twilight-struggle-preview" data-twilight-struggle-preview-inherited-display-value="${inherited}">
      <input type="hidden" value="${picked}" data-twilight-struggle-preview-target="display">
      ${kinds.join("")}
    </div>`
  await new Promise((resolve) => setTimeout(resolve, 0))
  return document.querySelector("[data-twilight-struggle-preview-target=winOutput]").textContent
}

afterEach(async () => {
  document.body.innerHTML = ""
  await new Promise((resolve) => setTimeout(resolve, 0))
})

test("inherit renders the inherited tag mode", async () => {
  assert.match(await connect({ picked: "", inherited: "tag" }), /@michal/)
})

test("an explicit pick wins over the inherited mode", async () => {
  assert.doesNotMatch(await connect({ picked: "name", inherited: "tag" }), /@michal/)
})
