<template>
  <div>
    <Head>
      <Title>Doughnut ~ Podcast App for macOS</Title>
    </Head>
    <div class="md:h-screen w-full relative overflow-hidden intro-gradient">
      <div class="absolute bottom-0 left-0">
        <svg class="mx-auto" width="1309px" height="977px" viewBox="0 0 1309 977" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
                <g transform="translate(0.000000, -46.000000)" fill="#F5589D">
                    <path d="M626,488 C712.156421,488 782,557.843579 782,644 C782,730.156421 712.156421,800 626,800 C539.843579,800 470,730.156421 470,644 C470,557.843579 539.843579,488 626,488 Z M626.5,597 C600.266474,597 579,618.266474 579,644.5 C579,670.733526 600.266474,692 626.5,692 C652.733526,692 674,670.733526 674,644.5 C674,618.266474 652.733526,597 626.5,597 Z" id="Combined-Shape" opacity="0.0446973528"></path>
                    <path d="M130.5,317 C188.213756,317 235,363.786244 235,421.5 C235,479.213756 188.213756,526 130.5,526 C72.7862436,526 26,479.213756 26,421.5 C26,363.786244 72.7862436,317 130.5,317 Z M131,390 C113.326888,390 99,404.326888 99,422 C99,439.673112 113.326888,454 131,454 C148.673112,454 163,439.673112 163,422 C163,404.326888 148.673112,390 131,390 Z" id="Combined-Shape" opacity="0.0405469622"></path>
                    <path d="M1204.5,46 C1262.21376,46 1309,92.7862436 1309,150.5 C1309,208.213756 1262.21376,255 1204.5,255 C1146.78624,255 1100,208.213756 1100,150.5 C1100,92.7862436 1146.78624,46 1204.5,46 Z M1205,119 C1187.32689,119 1173,133.326888 1173,151 C1173,168.673112 1187.32689,183 1205,183 C1222.67311,183 1237,168.673112 1237,151 C1237,133.326888 1222.67311,119 1205,119 Z" id="Combined-Shape" opacity="0.0301717122"></path>
                    <path d="M977.5,709 C1045.15488,709 1100,763.845118 1100,831.5 C1100,899.154882 1045.15488,954 977.5,954 C909.845118,954 855,899.154882 855,831.5 C855,763.845118 909.845118,709 977.5,709 Z M978.5,795 C957.789322,795 941,811.789322 941,832.5 C941,853.210678 957.789322,870 978.5,870 C999.210678,870 1016,853.210678 1016,832.5 C1016,811.789322 999.210678,795 978.5,795 Z" id="Combined-Shape" opacity="0.121894473"></path>
                    <path d="M59,800 C106.496488,800 145,838.503512 145,886 C145,933.496488 106.496488,972 59,972 C11.5035115,972 -27,933.496488 -27,886 C-27,838.503512 11.5035115,800 59,800 Z M59,860 C44.6405965,860 33,871.640597 33,886 C33,900.359403 44.6405965,912 59,912 C73.3594035,912 85,900.359403 85,886 C85,871.640597 73.3594035,860 59,860 Z" id="Combined-Shape" opacity="0.0384717669"></path>
                    <path d="M211,658 C239.166522,658 262,680.833478 262,709 C262,737.166522 239.166522,760 211,760 C182.833478,760 160,737.166522 160,709 C160,680.833478 182.833478,658 211,658 Z M211.5,694 C202.939586,694 196,700.939586 196,709.5 C196,718.060414 202.939586,725 211.5,725 C220.060414,725 227,718.060414 227,709.5 C227,700.939586 220.060414,694 211.5,694 Z" id="Combined-Shape" opacity="0.0384717669"></path>
                    <path d="M496.5,867 C554.213756,867 601,913.786244 601,971.5 C601,1029.21376 554.213756,1076 496.5,1076 C438.786244,1076 392,1029.21376 392,971.5 C392,913.786244 438.786244,867 496.5,867 Z M497,940 C479.326888,940 465,954.326888 465,972 C465,989.673112 479.326888,1004 497,1004 C514.673112,1004 529,989.673112 529,972 C529,954.326888 514.673112,940 497,940 Z" id="Combined-Shape" opacity="0.0898975191"></path>
                </g>
            </g>
        </svg>
      </div>
      <img src="~/assets/icon_underlay.png" class="logo-underlay" width="578" alt="">

      <div class="relative md:h-full pt-6 pb-16 overflow-hidden">
        <div class="container md:h-full flex flex-col">
          <div class="mb-12 md:mb-0">
            <a href="/">
              <logo class="w-24 h-24" />
            </a>
          </div>

          <div class="mt-8 md:mt-0 flex-grow md:flex md:items-center md:justify-center">
            <div class="mb-8 flex flex-col justify-center md:mb-0 md:w-5/12">
              <h1 class="font-title font-bold text-pink-500 text-5xl mb-2">Doughnut</h1>
              <p class="text-lg md:text-xl text-pink-muted">Uncluttered podcast listening app for Mac.</p>

              <div class="mt-6 mb-4 space-y-2 md:flex md:flex-wrap md:items-center lg:space-x-6 lg:flex-nowrap">
                <a href="https://github.com/dyerc/Doughnut" rel="noopener" target="_blank" class="primary-link">
                  <svg class="w-5 h-5" viewBox="0 0 19 19" xmlns="http://www.w3.org/2000/svg">
                    <path d="M6.355 14.603c0 .075-.088.135-.2.135-.126.012-.214-.048-.214-.135 0-.075.088-.135.2-.135.114-.01.214.05.214.135Zm-1.191-.168c-.027.075.05.16.164.183.1.038.215 0 .238-.075.023-.075-.05-.16-.165-.195-.1-.026-.21.012-.237.087Zm1.693-.064c-.111.026-.188.097-.176.184.011.075.11.123.226.097.11-.026.187-.097.176-.172-.012-.072-.115-.12-.226-.11ZM9.377 0C4.064 0 0 3.949 0 9.15a9.419 9.419 0 0 0 6.493 8.971c.49.086.663-.21.663-.454 0-.232-.012-1.515-.012-2.302 0 0-2.681.562-3.244-1.118 0 0-.437-1.091-1.065-1.372 0 0-.878-.59.061-.578 0 0 .954.075 1.479.968.839 1.447 2.244 1.03 2.792.783.088-.6.337-1.016.613-1.263-2.141-.233-4.302-.537-4.302-4.144 0-1.032.291-1.55.904-2.21-.1-.243-.425-1.248.1-2.546.8-.244 2.643 1.013 2.643 1.013a9.181 9.181 0 0 1 2.406-.319c.816 0 1.64.109 2.405.319 0 0 1.843-1.26 2.643-1.013.525 1.302.2 2.303.1 2.547.613.663.988 1.181.988 2.209 0 3.618-2.256 3.907-4.397 4.144.352.296.651.858.651 1.74 0 1.263-.012 2.827-.012 3.135 0 .244.177.54.663.454C16.402 16.869 19 13.31 19 9.15 19 3.949 14.69 0 9.377 0ZM3.723 12.935c-.05.037-.038.123.027.195.061.06.15.086.2.037.05-.037.038-.124-.027-.195-.062-.06-.15-.086-.2-.037Zm-.413-.304c-.027.049.011.109.088.146.061.038.138.026.164-.026.027-.049-.011-.109-.088-.146-.076-.023-.138-.012-.164.026Zm1.24 1.335c-.06.049-.037.161.05.232.089.087.2.098.25.038.05-.049.026-.161-.05-.233-.084-.086-.2-.097-.25-.037Zm-.436-.551c-.061.037-.061.135 0 .22.061.087.165.125.215.087.06-.049.06-.146 0-.232-.054-.087-.154-.124-.215-.075Z" fill="#FFF" fill-rule="nonzero"/>
                  </svg>

                  <strong>GitHub</strong>
                  <span>GPLv3</span>
                </a>

                <a href="https://github.com/dyerc/Doughnut/releases/download/v2.0.0.rc1/Doughnut-2.0.0-rc.1.dmg" class="primary-link">
                  <svg class="w-5 h-5" viewBox="0 0 20 19" xmlns="http://www.w3.org/2000/svg">
                    <g fill="#FFF" fill-rule="nonzero">
                      <path d="M20.003 8.014a4.85 4.85 0 0 0-1.475-3.467 4.75 4.75 0 0 0-2.875-1.325.208.208 0 0 1-.158-.1 6.4 6.4 0 0 0-11.75 1.917.208.208 0 0 1-.184.158 3.883 3.883 0 0 0-2.15.833A3.825 3.825 0 0 0 .003 9.014a3.608 3.608 0 0 0 1.033 2.675 4.65 4.65 0 0 0 3 1.15.833.833 0 1 0 0-1.667 2.8 2.8 0 0 1-1.808-.675 1.958 1.958 0 0 1-.558-1.483 2.15 2.15 0 0 1 2.6-2.109.833.833 0 0 0 .675-.158.833.833 0 0 0 .325-.608 4.733 4.733 0 0 1 9.016-1.742c.143.3.451.487.784.475a3.05 3.05 0 0 1 2.3.875c.62.59.97 1.41.966 2.267a3.192 3.192 0 0 1-2.866 3.158.84.84 0 1 0 .216 1.667 4.85 4.85 0 0 0 4.317-4.825Z"/>
                      <path d="M12.92 13.672H11.46a.208.208 0 0 1-.208-.208v-6a1.25 1.25 0 0 0-2.5 0v6a.208.208 0 0 1-.208.208H7.086a.833.833 0 0 0-.591 1.417l2.916 2.916a.833.833 0 0 0 1.184 0l2.916-2.916a.833.833 0 0 0-.591-1.417Z"/>
                    </g>
                  </svg>

                  <strong>Download</strong>
                  <span>v2.0.0</span>
                </a>
              </div>

              <p class="text-xs">Requires OS X 10.15+, the latest macOS recommended</p>
            </div>

            <div class="md:w-7/12 md:relative main-screenshot">
              <img src="~/assets/main_screenshot.png" alt="">
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="md:min-h-screen w-full features-gradient">
      <div class="max-w-4xl mx-auto py-20 px-6 text-center text-white">
        <h1 class="font-title font-bold text-4xl mb-4">Built from scratch for macOS</h1>

        <p class="opacity-90">Doughnut is built to be a modern macOS application adopting Apple’s design language, whilst preserving it’s own unique user experience. 100% open source Swift based.</p>

        <ul class="text-center feature-list">
          <li>
            <strong>Fast and Intuitive, Native Interface</strong>
          </li>
          <li>
            <strong>Favourite Episodes</strong>
          </li>
          <li>
            <strong>Search</strong>
          </li>
          <li>
            <strong>Custom Podcasts</strong>
            <i>(without an RSS feed of their own)</i>
          </li>
          <li>
            <strong>Flexible Library</strong>
            <i>(use a network location or even keep multiple libraries on your machine)</i>
          </li>
        </ul>
      </div>

      <carousel></carousel>
    </div>

    <div class="bg-pink-900 text-white text-sm pt-12 pb-16">
      <div class="max-w-4xl text-center opacity-90 mx-auto px-6">
        &copy; Copyright 2022 doughnutapp.com
      </div>
    </div>
  </div>
</template>

<script setup>
</script>

<style>
.intro-gradient {
  background-image: linear-gradient(180deg, #FFFBFD 0%, #FCCAE0 100%);
}

.features-gradient {
  background-image: radial-gradient(circle at 50% 0%, #4D142D 0%, #231A1E 78%);
}

.logo-underlay {
  @apply absolute top-0 -right-40;

  @screen md {
    right: initial;
    left: 50%;
    transform: translateX(-289px);
  }
}

.main-screenshot {
  @screen md {
    height: 70vh;
  }

  img {
    @screen md {
      @apply absolute left-8 top-0 bottom-0 h-full w-auto max-w-none;
    }
  }
}

.primary-link {
  @apply inline-flex items-baseline bg-pink-600 rounded-3xl py-3 px-7 mr-4 lg:mr-0 text-white transition-colors duration-200 ease-in-out hover:bg-pink-500;

  svg {
    @apply translate-y-1;
  }

  strong {
    @apply ml-3 mr-2 text-lg;
  }

  span {
    @apply text-sm opacity-70;
  }
}

.feature-list {
  @apply my-8 space-y-6;

  li strong {
    @apply block text-2xl font-title font-bold text-pink-500;
  }

  li i {
    @apply block text-sm;
  }
}
</style>