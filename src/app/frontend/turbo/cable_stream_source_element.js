/**
 * Custom element that connects Turbo Streams to ActionCable. Rendered by the
 * turbo_stream_from helper in views. When present in the DOM, it subscribes to
 * Turbo::StreamsChannel and forwards received messages to Turbo for DOM updates.
 */
import { connectStreamSource, disconnectStreamSource } from "@hotwired/turbo"
import { subscribeTo } from "./cable.js"
import { snakeize } from "./snakeize.js"

class TurboCableStreamSourceElement extends HTMLElement {
  static observedAttributes = ["channel", "signed-stream-name", "signed_stream_name"]

  connectedCallback() {
    connectStreamSource(this)
    const channelName = this.getAttribute("channel") || "Turbo::StreamsChannel"
    const signedStreamName =
      this.getAttribute("signed-stream-name") ?? this.getAttribute("signed_stream_name")
    try {
      this.subscription = subscribeTo(
        { channel: channelName, signed_stream_name: signedStreamName, ...snakeize({ ...this.dataset }) },
        {
          received: this.dispatchMessageEvent.bind(this),
          connected: this.subscriptionConnected.bind(this),
          disconnected: this.subscriptionDisconnected.bind(this)
        }
      )
    } catch (err) {
      console.error("[TurboCableStreamSource] subscribe error:", err)
    }
  }

  disconnectedCallback() {
    disconnectStreamSource(this)
    if (this.subscription) this.subscription.unsubscribe()
    this.subscriptionDisconnected()
  }

  attributeChangedCallback() {
    if (this.subscription) {
      this.disconnectedCallback()
      this.connectedCallback()
    }
  }

  dispatchMessageEvent(data) {
    this.dispatchEvent(new MessageEvent("message", { data }))
  }

  subscriptionConnected() {
    this.setAttribute("connected", "")
  }

  subscriptionDisconnected() {
    this.removeAttribute("connected")
  }
}

if (customElements.get("turbo-cable-stream-source") === undefined) {
  customElements.define("turbo-cable-stream-source", TurboCableStreamSourceElement)
}
