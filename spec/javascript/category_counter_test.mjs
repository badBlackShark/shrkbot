import { test, afterEach } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { installDom } from "./support/dom.mjs"
import { settle } from "./support/helpers.mjs"

installDom()

const { countStreams, normaliseLogin, readFilters, sentence } = await import("lib/category_count")
const { Application } = await import("@hotwired/stimulus")
const { default: CategoryCounterController } = await import("../../app/javascript/controllers/category_counter_controller.js")

const ROWS = [
  { viewers: 50, language: "en", login: "alpha" },
  { viewers: 10, language: "en", login: "beta" },
  { viewers: 30, language: "de", login: "gamma" },
  { viewers: 30, language: "fr", login: "delta" }
]
const everything = { minViewers: 0, languages: [], excluded: [] }

test("an empty language set and no exclusions count every row", () => {
  assert.equal(countStreams(ROWS, everything), 4)
})

test("the floor is inclusive", () => {
  assert.equal(countStreams(ROWS, { ...everything, minViewers: 30 }), 3)
  assert.equal(countStreams(ROWS, { ...everything, minViewers: 31 }), 1)
})

test("languages narrow the count to the picked ones", () => {
  assert.equal(countStreams(ROWS, { ...everything, languages: ["en", "de"] }), 3)
})

test("exclusions match however they were typed", () => {
  assert.equal(countStreams(ROWS, { ...everything, excluded: ["@Alpha", "https://www.twitch.tv/BETA/videos"] }), 2)
})

test("an empty row list counts nothing", () => {
  assert.equal(countStreams([], everything), 0)
})

const REFERENCES = JSON.parse(readFileSync(new URL("../fixtures/channel_references.json", import.meta.url), "utf8"))

test("normaliseLogin reads every reference the server reads", () => {
  for (const { input, login } of REFERENCES) {
    assert.equal(normaliseLogin(input), login, input)
  }
})

test("normaliseLogin trims surrounding whitespace", () => {
  assert.equal(normaliseLogin("  @SomeOne "), "someone")
})

test("sentence picks the none, one and many wording", () => {
  const strings = { none: "none", one: "one", many: "{number} many" }
  assert.equal(sentence(0, strings), "none")
  assert.equal(sentence(1, strings), "one")
  assert.equal(sentence(4, strings), "4 many")
})

test("readFilters reads the stepper and the picked options, ignoring the hidden blanks", () => {
  const form = {
    elements: [
      { name: "subscription[min_viewers]", value: "25" },
      { name: "subscription[languages][]", type: "hidden", value: "" },
      { name: "subscription[languages][]", selectedOptions: [{ value: "de" }, { value: "en" }] },
      { name: "subscription[excluded_channels][]", selectedOptions: [{ value: "alpha" }] }
    ]
  }
  assert.deepEqual(readFilters(form), { minViewers: 25, languages: ["de", "en"], excluded: ["alpha"] })
})

const application = Application.start()
application.register("category-counter", CategoryCounterController)

const realFetch = globalThis.fetch

function mount() {
  document.body.innerHTML = `
    <form>
      <input name="subscription[min_viewers]" value="0">
      <p data-controller="category-counter" data-category-counter-url-value="/streams"
         data-category-counter-none-value="none" data-category-counter-one-value="one"
         data-category-counter-many-value="{number} many" data-category-counter-failed-value="failed">Counting</p>
    </form>`
  return { floor: document.querySelector("input"), output: document.querySelector("p") }
}

function mountPickers() {
  document.body.innerHTML = `
    <form>
      <input name="subscription[min_viewers]" value="0">
      <select multiple name="subscription[languages][]">
        <option value="en">English</option><option value="de">German</option>
      </select>
      <select multiple name="subscription[excluded_channels][]">
        <option value="alpha">alpha</option><option value="beta">beta</option>
      </select>
      <p data-controller="category-counter" data-category-counter-url-value="/streams"
         data-category-counter-none-value="none" data-category-counter-one-value="one"
         data-category-counter-many-value="{number} many" data-category-counter-failed-value="failed">Counting</p>
    </form>`
  const pick = (name, values) => {
    const select = document.querySelector(`select[name='${name}']`)
    const labels = [...select.options].map((option) => [option.value, option.textContent])
    select.innerHTML = labels.map(([value, label]) => `<option value="${value}" ${values.includes(value) ? "selected" : ""}>${label}</option>`).join("")
    select.dispatchEvent(new Event("change", { bubbles: true }))
  }
  return { pick, output: document.querySelector("p") }
}

afterEach(async () => {
  globalThis.fetch = realFetch
  document.body.innerHTML = ""
  await settle()
})

test("the controller counts once loaded and again when the floor moves", async () => {
  globalThis.fetch = async () => ({ ok: true, json: async () => ROWS })
  const { floor, output } = mount()
  await settle()
  assert.equal(output.textContent, "4 many")

  floor.value = "50"
  floor.dispatchEvent(new Event("input", { bubbles: true }))
  assert.equal(output.textContent, "one")
})

test("the controller shows the failure text and does not retry", async () => {
  let calls = 0
  globalThis.fetch = async () => {
    calls += 1
    return { ok: false }
  }
  const { floor, output } = mount()
  await settle()
  floor.dispatchEvent(new Event("input", { bubbles: true }))

  assert.equal(output.textContent, "failed")
  assert.equal(calls, 1)
})

test("picking languages recounts from the select's own selection", async () => {
  globalThis.fetch = async () => ({ ok: true, json: async () => ROWS })
  const { pick, output } = mountPickers()
  await settle()
  assert.equal(output.textContent, "4 many")

  pick("subscription[languages][]", ["de"])
  assert.equal(output.textContent, "one")
})

test("picking excluded channels recounts from the select's own selection", async () => {
  globalThis.fetch = async () => ({ ok: true, json: async () => ROWS })
  const { pick, output } = mountPickers()
  await settle()

  pick("subscription[excluded_channels][]", ["alpha", "beta"])
  assert.equal(output.textContent, "2 many")
})
