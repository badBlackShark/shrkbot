const SERIALIZED_PROPERTIES = ["href", "target", "rel", "start"]

export function installFakeDocument() {
  globalThis.document = {
    createElement,
    createTextNode: (value) => ({ nodeName: "#text", textContent: value })
  }
}

export function serialize(node) {
  if (node.nodeName === "#text") return node.textContent
  return `<${node.nodeName}${serializeAttributes(node)}>${serializeChildren(node)}</${node.nodeName}>`
}

export function listenerCount(node, type) {
  return node.listeners.filter((listener) => listener.type === type).length
}

function createElement(nodeName) {
  return {
    nodeName,
    className: "",
    attributes: new Map(),
    childNodes: [],
    listeners: [],
    text: null,
    get textContent() {
      if (this.text !== null) return this.text
      return this.childNodes.map((child) => child.textContent).join("")
    },
    set textContent(value) {
      this.text = value
      this.childNodes = []
    },
    append(...nodes) {
      this.childNodes.push(...nodes)
    },
    setAttribute(name, value) {
      this.attributes.set(name, value)
    },
    addEventListener(type, handler) {
      this.listeners.push({ type, handler })
    }
  }
}

function serializeAttributes(node) {
  const pairs = node.className ? [["class", node.className]] : []
  pairs.push(...node.attributes)
  for (const name of SERIALIZED_PROPERTIES) {
    if (node[name] !== undefined) pairs.push([name, node[name]])
  }

  return pairs.map(([name, value]) => ` ${name}="${value}"`).join("")
}

function serializeChildren(node) {
  if (node.text !== null) return node.text
  return node.childNodes.map(serialize).join("")
}
