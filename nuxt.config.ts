import { defineNuxtConfig } from 'nuxt'

// https://v3.nuxtjs.org/api/configuration/nuxt.config
export default defineNuxtConfig({
  buildModules: ['@nuxtjs/tailwindcss'],
  app: {
    head: {
      link: [
        { rel: "stylesheet", href: "https://use.typekit.net/upd2bre.css" },

        { rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png" },
        { rel: "icon", type: "image/png", sizes: "32x32", href: "/favicon-32x32.png" },
        { rel: "icon", type: "image/png", sizes: "16x16", href: "/favicon-16x16.png" },
        { rel: "manifest", href: "/site.webmanifest" },
        { rel: "mask-icon", href: "/safari-pinned-tab.svg", color: "#cf206c" },
      ],
      meta: [
        { name: "msapplication-TileColor", content: "#ffffff" },
        { name: "theme-color", content: "#CF206C" }
      ]
    }
  },
  target: "static",
  tailwindcss: {
    jit: true,
    exposeConfig: true
  }
})
