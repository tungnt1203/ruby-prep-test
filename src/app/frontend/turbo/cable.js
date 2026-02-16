/**
 * ActionCable consumer (one per page). Connects to /cable by default via meta action-cable-url.
 * See Action Cable Overview: Consumers, subscriptions.create({ channel, ...params }).
 */
import { createConsumer } from "@rails/actioncable"

let consumer = null

export function getConsumer() {
  return consumer ?? (consumer = createConsumer())
}

export function subscribeTo(channelName, mixin) {
  const { subscriptions } = getConsumer()
  return subscriptions.create(channelName, mixin)
}
