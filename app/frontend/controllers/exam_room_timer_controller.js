import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "countdown"]
  static values = { endsAt: String }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  tick() {
    const endsAt = new Date(this.endsAtValue)
    const now = new Date()
    const diffMs = endsAt - now

    if (Number.isNaN(diffMs)) {
      if (this.hasCountdownTarget) this.countdownTarget.textContent = "--:--:--"
      return
    }

    if (diffMs <= 0) {
      if (this.interval) {
        clearInterval(this.interval)
        this.interval = null
      }
      if (this.hasCountdownTarget) this.countdownTarget.textContent = "Time's up!"
      if (this.hasFormTarget) this.formTarget.requestSubmit()
      return
    }

    const totalSeconds = Math.floor(diffMs / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60
    const pad = (n) => String(n).padStart(2, "0")
    const str = `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`

    if (this.hasCountdownTarget) this.countdownTarget.textContent = str
  }
}
