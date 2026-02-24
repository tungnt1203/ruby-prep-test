/**
 * Converts object keys from camelCase to snake_case for Rails channel params.
 * Used by turbo-cable-stream-source to pass data-* attributes to the channel.
 */
export function snakeize(obj) {
  if (obj == null || typeof obj !== "object") return obj
  const out = {}
  for (const [key, value] of Object.entries(obj)) {
    const snake = key.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`)
    out[snake] = value
  }
  return out
}
