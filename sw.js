/* دفتر الطلبيات — عامل الخدمة: يستقبل تنبيهات الهاتف حتى والموقع مسكّر */
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

self.addEventListener("push", (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch (e) {
    data = { body: event.data ? event.data.text() : "" };
  }
  const title = data.title || "دفتر الطلبيات 💗";
  event.waitUntil(
    self.registration.showNotification(title, {
      body: data.body || "يلا نزيدو طلبية جديدة! 💪",
      icon: "icon-192.png",
      badge: "icon-192.png",
      dir: "rtl",
      lang: "ar",
      tag: data.tag || "dafter-reminder",
      renotify: true,
      data: { url: data.url || "./" },
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || "./";
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if ("focus" in c) return c.focus();
      }
      return self.clients.openWindow(url);
    })
  );
});
