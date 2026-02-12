import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["countdown", "label", "startBlock"]
  static values = {
    startsAt: String,
    roomUrl: String
  }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  tick() {
    const startsAt = new Date(this.startsAtValue)
    const now = new Date()
    const diffMs = startsAt - now

    if (diffMs <= 0) {
      if (this.interval) {
        clearInterval(this.interval)
        this.interval = null
      }
      if (this.hasCountdownTarget) this.countdownTarget.textContent = "00:00:00"
      if (this.hasLabelTarget) this.labelTarget.textContent = "Started! You can begin."
      if (this.hasStartBlockTarget) this.startBlockTarget.style.display = "block"
      return
    }

    const totalSeconds = Math.floor(diffMs / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60
    const pad = (n) => String(n).padStart(2, "0")
    const str = `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`

    if (this.hasCountdownTarget) this.countdownTarget.textContent = str
    if (this.hasLabelTarget) this.labelTarget.textContent = "Time until start"
  }
}
