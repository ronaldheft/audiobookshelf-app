<template>
  <div ref="card" :id="`book-card-${index}`" :style="{ minWidth: width + 'px', maxWidth: width + 'px', height: height + 'px' }" class="rounded-sm z-10 bg-primary cursor-pointer box-shadow-book" @click="clickCard">
    <!-- When cover image does not fill -->
    <div v-show="showCoverBg" class="absolute top-0 left-0 w-full h-full overflow-hidden rounded-sm bg-primary">
      <div class="absolute cover-bg" ref="coverBg" />
    </div>

    <!-- Alternative bookshelf title/author/sort -->
    <div v-if="isAltViewEnabled" class="absolute left-0 z-50 w-full" :style="{ bottom: `-${titleDisplayBottomOffset}rem` }">
      <p class="truncate" :style="{ fontSize: 0.9 * sizeMultiplier + 'rem' }">
        {{ displayTitle }}
      </p>
      <p class="truncate text-gray-400" :style="{ fontSize: 0.8 * sizeMultiplier + 'rem' }">{{ displayAuthor || '&nbsp;' }}</p>
      <p v-if="displaySortLine" class="truncate text-gray-400" :style="{ fontSize: 0.8 * sizeMultiplier + 'rem' }">{{ displaySortLine }}</p>
    </div>

    <div v-if="booksInSeries" class="absolute z-20 top-1.5 right-1.5 rounded-md leading-3 text-sm p-1 font-semibold text-white flex items-center justify-center" style="background-color: #cd9d49dd">{{ booksInSeries }}</div>

    <div class="w-full h-full absolute top-0 left-0 rounded overflow-hidden z-10">
      <div v-show="libraryItem && !imageReady" class="absolute top-0 left-0 w-full h-full flex items-center justify-center" :style="{ padding: sizeMultiplier * 0.5 + 'rem' }">
        <p :style="{ fontSize: sizeMultiplier * 0.8 + 'rem' }" class="font-book text-gray-300 text-center">{{ title }}</p>
      </div>

      <img v-show="libraryItem" ref="cover" :src="bookCoverSrc" class="w-full h-full transition-opacity duration-300" :class="showCoverBg ? 'object-contain' : 'object-fill'" @load="imageLoaded" :style="{ opacity: imageReady ? 1 : 0 }" />

      <!-- Placeholder Cover Title & Author -->
      <div v-if="!hasCover" class="absolute top-0 left-0 right-0 bottom-0 w-full h-full flex items-center justify-center" :style="{ padding: placeholderCoverPadding + 'rem' }">
        <div>
          <p class="text-center font-book" style="color: rgb(247 223 187)" :style="{ fontSize: titleFontSize + 'rem' }">{{ titleCleaned }}</p>
        </div>
      </div>
      <div v-if="!hasCover" class="absolute left-0 right-0 w-full flex items-center justify-center" :style="{ padding: placeholderCoverPadding + 'rem', bottom: authorBottom + 'rem' }">
        <p class="text-center font-book" style="color: rgb(247 223 187); opacity: 0.75" :style="{ fontSize: authorFontSize + 'rem' }">{{ authorCleaned }}</p>
      </div>
    </div>

    <!-- Play/pause button for podcast episode -->
    <div v-if="recentEpisode" class="absolute z-10 top-0 left-0 bottom-0 right-0 m-auto flex items-center justify-center w-12 h-12 rounded-full bg-white bg-opacity-70">
      <span class="material-icons text-6xl text-black text-opacity-80">{{ streamIsPlaying ? 'pause_circle' : 'play_circle_filled' }}</span>
    </div>

    <!-- No progress shown for collapsed series in library -->
    <div v-if="!collapsedSeries && (!isPodcast || recentEpisode)" class="absolute bottom-0 left-0 h-1 shadow-sm max-w-full z-10 rounded-b" :class="itemIsFinished ? 'bg-success' : 'bg-yellow-400'" :style="{ width: width * userProgressPercent + 'px' }"></div>

    <div v-if="showHasLocalDownload" class="absolute right-0 top-0 z-20" :style="{ top: (isPodcast ? 1.75 : 0.375) * sizeMultiplier + 'rem', right: 0.375 * sizeMultiplier + 'rem', padding: `${0.1 * sizeMultiplier}rem ${0.25 * sizeMultiplier}rem` }">
      <span class="material-icons text-2xl text-success">{{ isLocalOnly ? 'task' : 'download_done' }}</span>
    </div>

    <!-- Error widget -->
    <div v-if="showError" :style="{ height: 1.5 * sizeMultiplier + 'rem', width: 2.5 * sizeMultiplier + 'rem' }" class="bg-error rounded-r-full shadow-md flex items-center justify-end border-r border-b border-red-300">
      <span class="material-icons text-red-100 pr-1" :style="{ fontSize: 0.875 * sizeMultiplier + 'rem' }">priority_high</span>
    </div>

    <!-- Series sequence -->
    <div v-if="seriesSequence && showSequence && !isSelectionMode" class="absolute rounded-lg bg-black bg-opacity-90 box-shadow-md z-10" :style="{ top: 0.375 * sizeMultiplier + 'rem', right: 0.375 * sizeMultiplier + 'rem', padding: `${0.1 * sizeMultiplier}rem ${0.25 * sizeMultiplier}rem` }">
      <p :style="{ fontSize: sizeMultiplier * 0.8 + 'rem' }">#{{ seriesSequence }}</p>
    </div>

    <!-- Podcast Episode # -->
    <div v-if="recentEpisodeNumber && !isSelectionMode" class="absolute rounded-lg bg-black bg-opacity-90 box-shadow-md z-10" :style="{ top: 0.375 * sizeMultiplier + 'rem', right: 0.375 * sizeMultiplier + 'rem', padding: `${0.1 * sizeMultiplier}rem ${0.25 * sizeMultiplier}rem` }">
      <p :style="{ fontSize: sizeMultiplier * 0.8 + 'rem' }">Episode #{{ recentEpisodeNumber }}</p>
    </div>

    <!-- Podcast Num Episodes -->
    <div v-else-if="numEpisodes && !isSelectionMode" class="absolute rounded-full bg-black bg-opacity-90 box-shadow-md z-10 flex items-center justify-center" :style="{ top: 0.375 * sizeMultiplier + 'rem', right: 0.375 * sizeMultiplier + 'rem', width: 1.25 * sizeMultiplier + 'rem', height: 1.25 * sizeMultiplier + 'rem' }">
      <p :style="{ fontSize: sizeMultiplier * 0.8 + 'rem' }">{{ numEpisodes }}</p>
    </div>
  </div>
</template>

<script>
import { Capacitor } from '@capacitor/core'

export default {
  props: {
    index: Number,
    width: {
      type: Number,
      default: 120
    },
    height: {
      type: Number,
      default: 192
    },
    bookCoverAspectRatio: Number,
    showSequence: Boolean,
    isAltViewEnabled: Boolean,
    bookMount: {
      // Book can be passed as prop or set with setEntity()
      type: Object,
      default: () => null
    },
    orderBy: String,
    filterBy: String,
    sortingIgnorePrefix: Boolean
  },
  data() {
    return {
      isProcessingReadUpdate: false,
      libraryItem: null,
      imageReady: false,
      rescanning: false,
      selected: false,
      isSelectionMode: false,
      showCoverBg: false,
      localLibraryItem: null
    }
  },
  watch: {
    bookMount: {
      handler(newVal) {
        if (newVal) {
          this.libraryItem = newVal
        }
      }
    }
  },
  computed: {
    showExperimentalFeatures() {
      return this.store.state.showExperimentalFeatures
    },
    _libraryItem() {
      return this.libraryItem || {}
    },
    isLocal() {
      return !!this._libraryItem.isLocal
    },
    isLocalOnly() {
      // Local item with no server match
      return this.isLocal && !this._libraryItem.libraryItemId
    },
    media() {
      return this._libraryItem.media || {}
    },
    mediaMetadata() {
      return this.media.metadata || {}
    },
    mediaType() {
      return this._libraryItem.mediaType
    },
    isPodcast() {
      return this.mediaType === 'podcast'
    },
    placeholderUrl() {
      return '/book_placeholder.jpg'
    },
    bookCoverSrc() {
      if (this.isLocal) {
        if (this.libraryItem.coverContentUrl) return Capacitor.convertFileSrc(this.libraryItem.coverContentUrl)
        return this.placeholderUrl
      }
      return this.store.getters['globals/getLibraryItemCoverSrc'](this._libraryItem, this.placeholderUrl)
    },
    libraryItemId() {
      return this._libraryItem.id
    },
    libraryId() {
      return this._libraryItem.libraryId
    },
    hasEbook() {
      return this.media.ebookFile
    },
    numTracks() {
      return this.media.numTracks
    },
    numEpisodes() {
      if (this.isLocal && this.isPodcast && this.media.episodes) return this.media.episodes.length
      return this.media.numEpisodes
    },
    processingBatch() {
      return this.store.state.processingBatch
    },
    booksInSeries() {
      // Only added to audiobook object when collapseSeries is enabled
      return this._libraryItem.booksInSeries
    },
    hasCover() {
      return !!this.media.coverPath
    },
    squareAspectRatio() {
      return this.bookCoverAspectRatio === 1
    },
    sizeMultiplier() {
      var baseSize = this.squareAspectRatio ? 192 : 120
      return this.width / baseSize
    },
    title() {
      return this.mediaMetadata.title || ''
    },
    playIconFontSize() {
      return Math.max(2, 3 * this.sizeMultiplier)
    },
    authors() {
      return this.mediaMetadata.authors || []
    },
    author() {
      if (this.isPodcast) return this.mediaMetadata.author
      return this.mediaMetadata.authorName
    },
    authorLF() {
      return this.mediaMetadata.authorNameLF
    },
    series() {
      // Only included when filtering by series or collapse series
      return this.mediaMetadata.series
    },
    seriesSequence() {
      return this.series ? this.series.sequence : null
    },
    recentEpisode() {
      // Only added to item when getting currently listening podcasts
      return this._libraryItem.recentEpisode
    },
    recentEpisodeNumber() {
      if (!this.recentEpisode) return null
      if (this.recentEpisode.episode) {
        return this.recentEpisode.episode.replace(/^#/, '')
      }
      return this.recentEpisode.index
    },
    collapsedSeries() {
      // Only added to item object when collapseSeries is enabled
      return this._libraryItem.collapsedSeries
    },
    booksInSeries() {
      // Only added to item object when collapseSeries is enabled
      return this.collapsedSeries ? this.collapsedSeries.numBooks : 0
    },
    displayTitle() {
      if (this.orderBy === 'media.metadata.title' && this.sortingIgnorePrefix && this.title.toLowerCase().startsWith('the ')) {
        return this.title.substr(4) + ', The'
      }
      return this.title
    },
    displayAuthor() {
      if (this.orderBy === 'media.metadata.authorNameLF') return this.authorLF
      return this.author
    },
    displaySortLine() {
      if (this.orderBy === 'mtimeMs') return 'Modified ' + this.$formatDate(this._libraryItem.mtimeMs)
      if (this.orderBy === 'birthtimeMs') return 'Born ' + this.$formatDate(this._libraryItem.birthtimeMs)
      if (this.orderBy === 'addedAt') return 'Added ' + this.$formatDate(this._libraryItem.addedAt)
      if (this.orderBy === 'media.duration') return 'Duration: ' + this.$elapsedPrettyExtended(this.media.duration, false)
      if (this.orderBy === 'size') return 'Size: ' + this.$bytesPretty(this._libraryItem.size)
      return null
    },
    episodeProgress() {
      // Only used on home page currently listening podcast shelf
      if (!this.recentEpisode) return null
      if (this.isLocal) return this.store.getters['globals/getLocalMediaProgressById'](this.libraryItemId, this.recentEpisode.id)
      return this.store.getters['user/getUserMediaProgress'](this.libraryItemId, this.recentEpisode.id)
    },
    userProgress() {
      if (this.recentEpisode) return this.episodeProgress || null
      if (this.isLocal) return this.store.getters['globals/getLocalMediaProgressById'](this.libraryItemId)
      return this.store.getters['user/getUserMediaProgress'](this.libraryItemId)
    },
    userProgressPercent() {
      return this.userProgress ? this.userProgress.progress || 0 : 0
    },
    itemIsFinished() {
      return this.userProgress ? !!this.userProgress.isFinished : false
    },
    showError() {
      return this.numMissingParts || this.isMissing || this.isInvalid
    },
    playerIsLocal() {
      return !!this.$store.state.playerIsLocal
    },
    localLibraryItemId() {
      if (this.isLocal) return this.libraryItemId
      return this.localLibraryItem ? this.localLibraryItem.id : null
    },
    isStreaming() {
      if (this.isPodcast) {
        if (this.playerIsLocal) {
          // Check is streaming local version of this episode
          return false // episode cards not implemented for local yet
        }
        return this.$store.getters['getIsEpisodeStreaming'](this.libraryItemId, this.recentEpisode.id)
      } else {
        return false // not yet necessary for books
      }
    },
    streamIsPlaying() {
      return this.$store.state.playerIsPlaying && this.isStreaming
    },
    isMissing() {
      return this._libraryItem.isMissing
    },
    isInvalid() {
      return this._libraryItem.isInvalid
    },
    numMissingParts() {
      if (this.isPodcast) return 0
      return this.media.numMissingParts
    },
    overlayWrapperClasslist() {
      var classes = []
      if (this.isSelectionMode) classes.push('bg-opacity-60')
      else classes.push('bg-opacity-40')
      if (this.selected) {
        classes.push('border-2 border-yellow-400')
      }
      return classes
    },
    store() {
      return this.$store || this.$nuxt.$store
    },
    userCanUpdate() {
      return this.store.getters['user/getUserCanUpdate']
    },
    userCanDelete() {
      return this.store.getters['user/getUserCanDelete']
    },
    userCanDownload() {
      return this.store.getters['user/getUserCanDownload']
    },
    userIsRoot() {
      return this.store.getters['user/getIsRoot']
    },
    _socket() {
      return this.$root.socket || this.$nuxt.$root.socket
    },
    titleFontSize() {
      return 0.75 * this.sizeMultiplier
    },
    authorFontSize() {
      return 0.6 * this.sizeMultiplier
    },
    placeholderCoverPadding() {
      return 0.8 * this.sizeMultiplier
    },
    authorBottom() {
      return 0.75 * this.sizeMultiplier
    },
    titleCleaned() {
      if (!this.title) return ''
      if (this.title.length > 60) {
        return this.title.slice(0, 57) + '...'
      }
      return this.title
    },
    authorCleaned() {
      if (!this.author) return ''
      if (this.author.length > 30) {
        return this.author.slice(0, 27) + '...'
      }
      return this.author
    },
    titleDisplayBottomOffset() {
      if (!this.isAltViewEnabled) return 0
      else if (!this.displaySortLine) return 3 * this.sizeMultiplier
      return 4.25 * this.sizeMultiplier
    },
    showHasLocalDownload() {
      if (this.localLibraryItem || this.isLocal) {
        if (this.recentEpisode && !this.isLocal) {
          const localEpisode = this.localLibraryItem.media.episodes.find((ep) => ep.serverEpisodeId === this.recentEpisode.id)
          return !!localEpisode
        } else {
          return true
        }
      }
      return false
    }
  },
  methods: {
    setSelectionMode(val) {
      this.isSelectionMode = val
      if (!val) this.selected = false
    },
    setEntity(_libraryItem) {
      var libraryItem = _libraryItem

      // this code block is only necessary when showing a selected series with sequence #
      //   it will update the selected series so we get realtime updates for series sequence changes
      if (this.series) {
        // i know.. but the libraryItem passed to this func cannot be modified so we need to create a copy
        libraryItem = {
          ..._libraryItem,
          media: {
            ..._libraryItem.media,
            metadata: {
              ..._libraryItem.media.metadata
            }
          }
        }
        var mediaMetadata = libraryItem.media.metadata
        if (mediaMetadata.series) {
          var newSeries = mediaMetadata.series.find((se) => se.id === this.series.id)
          if (newSeries) {
            // update selected series
            libraryItem.media.metadata.series = newSeries
            this.libraryItem = libraryItem
            return
          }
        }
      }

      this.libraryItem = libraryItem
    },
    setLocalLibraryItem(localLibraryItem) {
      // Server books may have a local library item
      this.localLibraryItem = localLibraryItem
    },
    clickCard(e) {
      if (this.isSelectionMode) {
        e.stopPropagation()
        e.preventDefault()
        this.selectBtnClick()
      } else if (this.recentEpisode) {
        var eventBus = this.$eventBus || this.$nuxt.$eventBus
        if (this.streamIsPlaying) {
          eventBus.$emit('pause-item')
          return
        }

        if (this.localLibraryItem) {
          const localEpisode = this.localLibraryItem.media.episodes.find((ep) => ep.serverEpisodeId === this.recentEpisode.id)
          if (localEpisode) {
            // Play episode locally
            eventBus.$emit('play-item', {
              libraryItemId: this.localLibraryItemId,
              episodeId: localEpisode.id,
              serverLibraryItemId: this.libraryItemId,
              serverEpisodeId: this.recentEpisode.id
            })
            return
          }
        }

        eventBus.$emit('play-item', { libraryItemId: this.libraryItemId, episodeId: this.recentEpisode.id })
      } else {
        var router = this.$router || this.$nuxt.$router
        if (router) {
          if (this.collapsedSeries) router.push(`/library/${this.libraryId}/series/${this.collapsedSeries.id}`)
          else router.push(`/item/${this.libraryItemId}`)
        }
      }
    },
    editClick() {
      this.$emit('edit', this.libraryItem)
    },
    toggleFinished() {
      var updatePayload = {
        isFinished: !this.itemIsFinished
      }
      this.isProcessingReadUpdate = true
      var toast = this.$toast || this.$nuxt.$toast
      var axios = this.$axios || this.$nuxt.$axios
      axios
        .$patch(`/api/me/progress/${this.libraryItemId}`, updatePayload)
        .then(() => {
          this.isProcessingReadUpdate = false
          toast.success(`Item marked as ${updatePayload.isFinished ? 'Finished' : 'Not Finished'}`)
        })
        .catch((error) => {
          console.error('Failed', error)
          this.isProcessingReadUpdate = false
          toast.error(`Failed to mark as ${updatePayload.isFinished ? 'Finished' : 'Not Finished'}`)
        })
    },
    rescan() {
      this.rescanning = true
      this.$axios
        .$get(`/api/items/${this.libraryItemId}/scan`)
        .then((data) => {
          this.rescanning = false
          var result = data.result
          if (!result) {
            this.$toast.error(`Re-Scan Failed for "${this.title}"`)
          } else if (result === 'UPDATED') {
            this.$toast.success(`Re-Scan complete item was updated`)
          } else if (result === 'UPTODATE') {
            this.$toast.success(`Re-Scan complete item was up to date`)
          } else if (result === 'REMOVED') {
            this.$toast.error(`Re-Scan complete item was removed`)
          }
        })
        .catch((error) => {
          console.error('Failed to scan library item', error)
          this.$toast.error('Failed to scan library item')
          this.rescanning = false
        })
    },
    showEditModalTracks() {
      // More menu func
      this.store.commit('showEditModalOnTab', { libraryItem: this.libraryItem, tab: 'tracks' })
    },
    showEditModalMatch() {
      // More menu func
      this.store.commit('showEditModalOnTab', { libraryItem: this.libraryItem, tab: 'match' })
    },
    showEditModalDownload() {
      // More menu func
      this.store.commit('showEditModalOnTab', { libraryItem: this.libraryItem, tab: 'download' })
    },
    openCollections() {
      this.store.commit('setSelectedLibraryItem', this.libraryItem)
      this.store.commit('globals/setShowUserCollectionsModal', true)
    },
    clickReadEBook() {
      this.store.commit('showEReader', this.libraryItem)
    },
    selectBtnClick() {
      if (this.processingBatch) return
      this.selected = !this.selected
      this.$emit('select', this.libraryItem)
    },
    destroy() {
      // destroy the vue listeners, etc
      this.$destroy()

      // remove the element from the DOM
      if (this.$el && this.$el.parentNode) {
        this.$el.parentNode.removeChild(this.$el)
      } else if (this.$el && this.$el.remove) {
        this.$el.remove()
      }
    },
    setCoverBg() {
      if (this.$refs.coverBg) {
        this.$refs.coverBg.style.backgroundImage = `url("${this.bookCoverSrc}")`
      }
    },
    imageLoaded() {
      this.imageReady = true

      if (this.$refs.cover && this.bookCoverSrc !== this.placeholderUrl) {
        var { naturalWidth, naturalHeight } = this.$refs.cover
        var aspectRatio = naturalHeight / naturalWidth
        var arDiff = Math.abs(aspectRatio - this.bookCoverAspectRatio)

        // If image aspect ratio is <= 1.45 or >= 1.75 then use cover bg, otherwise stretch to fit
        if (arDiff > 0.15) {
          this.showCoverBg = true
          this.$nextTick(this.setCoverBg)
        } else {
          this.showCoverBg = false
        }
      }
    }
  },
  mounted() {
    if (this.bookMount) {
      this.setEntity(this.bookMount)

      if (this.bookMount.localLibraryItem) {
        this.setLocalLibraryItem(this.bookMount.localLibraryItem)
      }
    }
  }
}
</script>
