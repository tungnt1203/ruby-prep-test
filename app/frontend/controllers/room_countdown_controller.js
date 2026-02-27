import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["countdown", "label", "startBlock"]
  static values = {
    startsAt: String,
    endsAt: String,
    roomUrl: String,
    isHost: Boolean
  }

  connect() {
    const run = () => {
      this.tick()
      this.interval = setInterval(() => this.tick(), 1000)
    }
    if (typeof requestAnimationFrame !== "undefined") {
      requestAnimationFrame(run)
    } else {
      run()
    }
    // When Turbo Stream replaces #room_countdown_section (host started), run tick() right after DOM update
    this._streamHandler = () => {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => this.tick())
      })
    }
    document.addEventListener("turbo:before-stream-render", this._streamHandler)
    // Fallback: when the section div is replaced by Turbo Stream, run tick()
    this._observer = new MutationObserver(() => {
      requestAnimationFrame(() => this.tick())
    })
    this._observer.observe(this.element, { childList: true, subtree: false })
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
    document.removeEventListener("turbo:before-stream-render", this._streamHandler)
    if (this._observer) this._observer.disconnect()
  }

  get startsAtValueFromDom() {
    const section = this.element.querySelector("#room_countdown_section")
    if (section) {
      const v = section.getAttribute("data-room-countdown-starts-at-value")
      if (v) return v
    }
    return this.element.getAttribute("data-room-countdown-starts-at-value") || this.startsAtValue || ""
  }

  get endsAtValueFromDom() {
    const section = this.element.querySelector("#room_countdown_section")
    if (section) {
      const v = section.getAttribute("data-room-countdown-ends-at-value")
      if (v) return v.trim() || ""
    }
    return (this.element.getAttribute("data-room-countdown-ends-at-value") || this.endsAtValue || "").trim()
  }

  tick() {
    // Prefer value from #room_countdown_section so when Turbo Stream replaces it (host starts), we use the new starts_at
    const raw = (this.startsAtValueFromDom || this.startsAtValue || "").trim()
    if (!raw || typeof raw !== "string" || raw.trim() === "") {
      if (this.hasCountdownTarget) this.countdownTarget.textContent = "--:--:--"
      if (this.hasLabelTarget) this.labelTarget.textContent = "Loading..."
      return
    }

    const startsAt = new Date(raw.trim())
    if (Number.isNaN(startsAt.getTime())) {
      if (this.hasCountdownTarget) this.countdownTarget.textContent = "--:--:--"
      if (this.hasLabelTarget) this.labelTarget.textContent = "Invalid start time"
      return
    }

    const now = new Date()
    const diffMs = startsAt - now

    if (diffMs <= 0) {
      // Exam started: show "time remaining" countdown if ends_at is set, else show static "Started!"
      const endsAtRaw = this.endsAtValueFromDom
      if (endsAtRaw) {
        const endsAt = new Date(endsAtRaw)
        if (!Number.isNaN(endsAt.getTime())) {
          const remainingMs = endsAt - now
          if (remainingMs > 0) {
            const totalSeconds = Math.floor(remainingMs / 1000)
            const hours = Math.floor(totalSeconds / 3600)
            const minutes = Math.floor((totalSeconds % 3600) / 60)
            const seconds = totalSeconds % 60
            const pad = (n) => String(n).padStart(2, "0")
            const str = `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`
            if (this.hasCountdownTarget) this.countdownTarget.textContent = str
            if (this.hasLabelTarget) this.labelTarget.textContent = "Time remaining"
            if (this.hasStartBlockTarget) this.startBlockTarget.style.display = "block"
            this._redirectCandidateOnce()
            return
          }
          // Time's up
          if (this.interval) {
            clearInterval(this.interval)
            this.interval = null
          }
          if (this.hasCountdownTarget) this.countdownTarget.textContent = "00:00:00"
          if (this.hasLabelTarget) this.labelTarget.textContent = "Time's up!"
          if (this.hasStartBlockTarget) this.startBlockTarget.style.display = "block"
          this._redirectCandidateOnce()
          return
        }
      }
      // No duration / no ends_at: show static "Started!"
      if (this.interval) {
        clearInterval(this.interval)
        this.interval = null
      }
      if (this.hasCountdownTarget) this.countdownTarget.textContent = "00:00:00"
      if (this.hasLabelTarget) this.labelTarget.textContent = "Started! You can begin."
      if (this.hasStartBlockTarget) this.startBlockTarget.style.display = "block"
      this._redirectCandidateOnce()
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

  _redirectCandidateOnce() {
    if (this._redirected || !this.hasRoomUrlValue || this.isHostValue) return
    this._redirected = true
    const url = this.roomUrlValue
    if (typeof Turbo !== "undefined" && Turbo.visit) {
      Turbo.visit(url)
    } else {
      window.location.href = url
    }
  }
}
