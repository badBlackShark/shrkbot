import { Window } from "happy-dom"

const GLOBALS = ["document", "HTMLElement", "Element", "Node", "getComputedStyle", "KeyboardEvent", "MouseEvent", "Event", "CustomEvent", "MutationObserver"]

export function installDom() {
  const window = new Window()
  for (const name of GLOBALS) globalThis[name] = window[name]
  globalThis.window = window
  return window
}
