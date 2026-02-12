import { Controller } from "@hotwired/stimulus"

// Trang kết quả: sidebar màu đúng/sai, xem từng câu, Next/Prev
export default class extends Controller {
  static targets = ["questionPanel", "questionItem"]
  static values = { total: { type: Number, default: 50 }, current: { type: Number, default: 0 } }

  connect() {
    this.showQuestion(this.currentValue)
  }

  currentValueChanged() {
    this.updateVisibility()
  }

  goTo(event) {
    const index = parseInt(event.currentTarget.dataset.questionIndex, 10)
    if (!Number.isNaN(index)) this.currentValue = index
  }

  next() {
    if (this.currentValue < this.totalValue - 1) this.currentValue++
  }

  prev() {
    if (this.currentValue > 0) this.currentValue--
  }

  showQuestion(index) {
    const i = Math.max(0, Math.min(index, this.totalValue - 1))
    this.currentValue = i
    this.updateVisibility()
  }

  updateVisibility() {
    const i = typeof this.currentValue === "number" ? this.currentValue : 0
    if (this.hasQuestionPanelTarget) {
      this.questionPanelTargets.forEach((panel) => {
        const panelIndex = parseInt(panel.dataset.questionIndex, 10)
        panel.classList.toggle("hidden", panelIndex !== i)
      })
    }
    if (this.hasQuestionItemTarget) {
      this.questionItemTargets.forEach((item) => {
        const itemIndex = parseInt(item.dataset.questionIndex, 10)
        const correct = item.dataset.questionCorrect
        const isCurrent = itemIndex === i
        item.classList.remove(
          "bg-indigo-600", "text-white",
          "bg-emerald-500", "text-white",
          "bg-rose-400", "text-white",
          "bg-slate-200", "text-slate-600"
        )
        if (isCurrent) {
          item.classList.add("bg-indigo-600", "text-white")
        } else if (correct === "true") {
          item.classList.add("bg-emerald-500", "text-white")
        } else if (correct === "false") {
          item.classList.add("bg-rose-400", "text-white")
        } else {
          item.classList.add("bg-slate-200", "text-slate-600")
        }
      })
    }
  }
}
