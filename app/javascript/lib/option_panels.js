export function showPanels(panels, selected) {
  panels.forEach((panel) => {
    panel.hidden = panel.dataset.value !== selected
  })
}
