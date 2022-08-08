<template>
  <div class="pb-20">
    <div ref="glide" class="glide">
      <div id="screenshot-gallery" data-glide-el="track" class="glide__track">
        <ul class="glide__slides">
          <li v-for="(slide, i) of screenshots" :key="i" class="glide__slide">
            <a :href="`../assets/${slide.asset}`" :data-pswp-width="slide.width" :data-pswp-height="slide.height">
              <img :src="`../assets/${slide.asset}`" alt="" />
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import Glide from '@glidejs/glide';
import PhotoSwipeLightbox from 'photoswipe/lightbox';

export default {
  data() {
    return {
      screenshots: [
        { 
          asset: "screenshot_1.png",
          width: 2230,
          height: 1412
        },
        { 
          asset: "screenshot_2.png",
          width: 2230,
          height: 1412
        },
        { 
          asset: "podcast_info.png",
          width: 1278,
          height: 942
        },
        { 
          asset: "episode_info.png",
          width: 1266,
          height: 950
        },
        { 
          asset: "custom_podcast.png",
          width: 2064,
          height: 1262
        },
        { 
          asset: "main_screenshot.png",
          width: 2340,
          height: 1434
        }
      ]
    }
  },

  mounted() {
    if (!this.lightbox) {
      this.lightbox = new PhotoSwipeLightbox({
        gallery: '#screenshot-gallery',
        children: 'a',
        pswpModule: () => import('photoswipe'),
      });
      this.lightbox.init();
    }

    this.glide = new Glide(this.$refs.glide, {
      type: 'carousel',
      perView: 2,
      focusAt: 'center'
    }).mount();
  }
}
</script>

<style>
@import "../node_modules/@glidejs/glide/dist/css/glide.core.min.css";
@import "../node_modules/photoswipe/dist/photoswipe.css";
</style>