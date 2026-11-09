export function noResultsHtml({ failed, failureText, escape }) {
  return `<div class="no-results">${escape(failed ? failureText : "No results found")}</div>`
}
