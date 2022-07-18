import { defineNuxtConfig } from 'nuxt'

// https://v3.nuxtjs.org/api/configuration/nuxt.config
export default defineNuxtConfig({
  buildModules: ['@nuxtjs/tailwindcss'],
  app: {
    head: {
      link: [
        { rel: "stylesheet", href: "https://use.typekit.net/upd2bre.css" }
      ]
    }
  },
  target: "static",
  tailwindcss: {
    jit: true,
    exposeConfig: true
  }
})
