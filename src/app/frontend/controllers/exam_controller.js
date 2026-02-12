import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["questionPanel", "questionItem"]
  static values = { total: { type: Number, default: 50 }, current: { type: Number, default: 0 } }

  connect() {
    this._answeredIndices = new Set()
    this.syncAnsweredFromForm()
    this.showQuestion(this.currentValue)
  }

  get answeredIndices() {
    if (!this._answeredIndices) this._answeredIndices = new Set()
    return this._answeredIndices
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

  /** Khi user chọn/bỏ chọn đáp án → cập nhật trạng thái "đã làm" trong sidebar */
  markAnswered(event) {
    const panel = event.target.closest("[data-exam-target='questionPanel']")
    if (!panel) return
    const index = parseInt(panel.dataset.questionIndex, 10)
    if (Number.isNaN(index)) return
    if (this.isQuestionAnswered(index)) {
      this.answeredIndices.add(index)
    } else {
      this.answeredIndices.delete(index)
    }
    this.updateSidebarState()
  }

  /** Kiểm tra câu có ít nhất một đáp án được chọn (radio hoặc checkbox) */
  isQuestionAnswered(index) {
    if (!this.hasQuestionPanelTarget) return false
    const panel = this.questionPanelTargets.find((p) => parseInt(p.dataset.questionIndex, 10) === index)
    if (!panel) return false
    const checked = panel.querySelector("input:checked")
    const multiChecked = panel.querySelectorAll("input:checked")
    const isMulti = panel.querySelector("input[type='checkbox']") != null
    if (isMulti) return multiChecked.length > 0
    return !!checked
  }

  /** Đồng bộ answeredIndices từ form (khi load / back) */
  syncAnsweredFromForm() {
    this.answeredIndices.clear()
    if (!this.hasQuestionPanelTarget) return
    this.questionPanelTargets.forEach((panel) => {
      const index = parseInt(panel.dataset.questionIndex, 10)
      if (!Number.isNaN(index) && this.isQuestionAnswered(index)) this.answeredIndices.add(index)
    })
  }

  showQuestion(index) {
    const i = Math.max(0, Math.min(index, this.totalValue - 1))
    this.currentValue = i
    this.updateVisibility()
  }

  updateVisibility() {
    const i = this.currentValue
    if (this.hasQuestionPanelTarget) {
      this.questionPanelTargets.forEach((panel) => {
        const panelIndex = parseInt(panel.dataset.questionIndex, 10)
        panel.classList.toggle("hidden", panelIndex !== i)
      })
    }
    this.updateSidebarState()
  }

  /** Sidebar: ⚪ Chưa làm | 🔵 Đã chọn đáp án | 👉 Đang xem (current) */
  updateSidebarState() {
    if (!this.hasQuestionItemTarget) return
    const i = typeof this.currentValue === "number" ? this.currentValue : 0
    this.questionItemTargets.forEach((item) => {
      const itemIndex = parseInt(item.dataset.questionIndex, 10)
      const isCurrent = itemIndex === i
      const isAnswered = this.answeredIndices.has(itemIndex)
      item.classList.remove("bg-indigo-600", "text-white", "bg-indigo-100", "text-indigo-700", "ring-2", "ring-indigo-400", "bg-slate-100", "text-slate-700")
      if (isCurrent) {
        item.classList.add("bg-indigo-600", "text-white")
      } else if (isAnswered) {
        item.classList.add("bg-indigo-100", "text-indigo-700", "ring-2", "ring-indigo-400")
      } else {
        item.classList.add("bg-slate-100", "text-slate-700")
      }
    })
  }
}
