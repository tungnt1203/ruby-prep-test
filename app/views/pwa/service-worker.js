// PWA Service Worker — Ruby Prep Test
// Caches app shell for offline; network-first for API/navigation.

const CACHE_NAME = "ruby-prep-test-v1"

self.addEventListener("install", (event) => {
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((names) => {
      return Promise.all(
        names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))
      )
    }).then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (event) => {
  const { request } = event
  const url = new URL(request.url)

  // Only same-origin GET requests
  if (url.origin !== self.location.origin || request.method !== "GET") {
    return
  }

  // API / Turbo / HTML: network first
  if (
    url.pathname.startsWith("/cable") ||
    request.headers.get("Accept")?.includes("text/vnd.turbo-stream") ||
    request.headers.get("Accept")?.includes("text/html")
  ) {
    event.respondWith(
      fetch(request).catch(() => caches.match(request))
    )
    return
  }

  // Static assets (JS, CSS, images, fonts): cache first
  if (
    /\.(js|css|woff2?|png|svg|ico|webp)(\?.*)?$/i.test(url.pathname) ||
    url.pathname === "/manifest" ||
    url.pathname === "/icon.svg" ||
    url.pathname === "/icon.png"
  ) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(request).then((cached) => {
          if (cached) return cached
          return fetch(request).then((res) => {
            if (res.ok) cache.put(request, res.clone())
            return res
          })
        })
      })
    )
    return
  }

  // Default: network first
  event.respondWith(
    fetch(request).catch(() => caches.match(request))
  )
})
