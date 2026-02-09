import { Controller } from "@hotwired/stimulus"

// Polls room participants JSON and updates counts + list (for host view).
export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 10000 }
  }

  static targets = ["countJoined", "countSubmitted", "list"]

  connect() {
    this.fetchParticipants()
    this.interval = setInterval(() => this.fetchParticipants(), this.intervalValue)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  async fetchParticipants() {
    if (!this.urlValue) return
    try {
      const res = await fetch(this.urlValue, { headers: { "Accept": "application/json" } })
      if (!res.ok) return
      const data = await res.json()
      if (this.hasCountJoinedTarget) this.countJoinedTarget.textContent = data.participants_count ?? 0
      if (this.hasCountSubmittedTarget) this.countSubmittedTarget.textContent = data.submitted_count ?? 0
      if (this.hasListTarget && data.participants && data.participants.length > 0) {
        this.listTarget.innerHTML = data.participants.map(p =>
          `<div class="text-xs text-slate-600">${escapeHtml(p.display_name)} ${p.submitted ? "✓" : ""}</div>`
        ).join("")
      }
    } catch (_e) {}
  }
}

function escapeHtml(s) {
  const div = document.createElement("div")
  div.textContent = s
  return div.innerHTML
}
