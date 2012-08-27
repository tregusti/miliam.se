# system modules
Path = require 'path'

# spec helpers
chai = require 'chai'
should = chai.should()
expect = chai.expect
spies = require 'chai-spies'
chai.use spies

spyfs = require './helpers/spy-fs'

# own code
ArgumentError = require '../lib/errors/argument'
Entry = require '../lib/entry'

describe 'Entry', ->
  afterEach -> spyfs.off()

  it 'should exist', ->
    expect(Entry).to.be.defined

  describe '#load', ->
    it 'should exist', ->
      expect(Entry.load).to.be.defined
    it 'should take 3 param', ->
      Entry.load.should.have.length 3
    it 'throws an error when path is undefined', ->
      Entry.load.should.throw ArgumentError
    it 'throws an error when path is empty', ->
      (-> Entry.load '').should.throw ArgumentError

    describe 'with valid entry data', ->

      it "should be an Entry", (done) ->
        spy = spyfs.on '/tmp/callback-invocation/info.txt', 'title: Hepp hopp'
        Entry.load spy.dirname, (err, entry) ->
          expect(entry).to.be.an.instanceof Entry
          done()

      it 'should invoke callback with entry and no error', (done) ->
        spy = spyfs.on '/tmp/callback-invocation/info.txt', 'hepp: hopp'
        Entry.load spy.dirname, (err, entry) ->
          expect(err).to.be.null
          expect(entry).to.be.defined
          done()

      describe 'when loaded', ->
        it 'should have a basepath', (done) ->
          spy = spyfs.on '/tmp/basepath/info.txt', 'glenn'
          Entry.load spy.dirname, (err, entry) ->
            entry.should.have.a.property 'basepath', Path.resolve spy.dirname
            done()




        # TIME PARSING

        describe 'time property', ->

          it 'defaults to null', (done) ->
            spy = spyfs.on '/tmp/time-prop/info.txt', "title: Title"
            Entry.load spy.dirname, (err, entry) ->
              entry.should.have.property 'time', null
              done()

          it 'defaults to today but uses specified time', (done) ->
            spy = spyfs.on '/tmp/time-prop/info.txt', 'time: 13:00:00'
            Entry.load spy.dirname, (err, entry) ->
              dateStr = new Date().toISOString().substr(0, 10)
              d = new Date dateStr + ' 13:00:00'
              entry.time.toLocaleString().should.equal d.toLocaleString()
              done()

          it 'uses specified date and time', (done) ->
            spy = spyfs.on '/tmp/time-prop/info.txt', 'date: 2011-12-24\ntime: 15:00:00'
            Entry.load spy.dirname, (err, entry) ->
              entry.time.toLocaleString().should.equal new Date("2011-12-24 15:00:00").toLocaleString()
              done()

          it 'allows for missing seconds', (done) ->
            spy = spyfs.on '/tmp/time-prop/info.txt', 'date: 2011-12-24\ntime: 15:25'
            Entry.load spy.dirname, (err, entry) ->
              entry.time.toLocaleString().should.equal new Date("2011-12-24 15:25:00").toLocaleString()
              done()

          it "uses the corect timezone, no matter if it's currently winter/summer time", (done) ->
            spy = spyfs.on '/tmp/time-prop/info.txt', 'date: 2011-12-24\ntime: 15:25'
            Entry.load spy.dirname, (err, entry) ->
              entry.time.toLocaleString().should.equal new Date("2011-12-24 15:25:00").toLocaleString()
              done()

          it "uses the correct timezone, no matter if it's currently winter/summer time", (done) ->
            spy = spyfs.on '/tmp/time-prop/info.txt', 'date: 2011-06-24\ntime: 15:25'
            Entry.load spy.dirname, (err, entry) ->
              entry.time.toLocaleString().should.equal new Date("2011-06-24 15:25:00").toLocaleString()
              done()



        # HUMANIZED TIME PROPS

        describe 'human time', ->
          entry = null
          before (done) ->
            spy = spyfs.on '/tmp/human-time/info.txt', 'date: 2012-06-06\ntime: 3:14'
            Entry.load Path.dirname(spy.path), (err, _entry) ->
              entry = _entry
              done()
          it 'has a pretty date prop', ->
            entry.should.have.property 'humanDate', "6 jun 2012"
          it 'has a zero padded pretty time prop', ->
            entry.should.have.property 'humanTime', "03:14"
          it 'is readonly', ->
            entry.humanTime = 'nope'
            entry.humanDate = 'nope'
            entry.should.have.property 'humanTime', "03:14"
            entry.should.have.property 'humanDate', "6 jun 2012"







      # IMAGE INFO

      describe 'with image meta data', ->
        it 'should be null when no images', (done) ->
          spy = spyfs.on '/tmp/no-image/info.txt', 'title: only'
          Entry.load spy.dirname, (err, entry) ->
            entry.should.have.property 'images', null
            done()

        it 'should have props for multiple images', (done) ->
          spy = spyfs.on '/tmp/no-image/info.txt', 'image: sia\nimage: glenn'
          Entry.load spy.dirname, images: true, (err, entry) ->
            entry.should.have.deep.property 'images[0].original', '/tmp/no-image/sia.original.jpg'
            entry.should.have.deep.property 'images[0].w320',     '/tmp/no-image/sia.w320.jpg'
            entry.should.have.deep.property 'images[0].w640',     '/tmp/no-image/sia.w640.jpg'
            entry.should.have.deep.property 'images[0].w1024',    '/tmp/no-image/sia.w1024.jpg'
            entry.should.have.deep.property 'images[1].original', '/tmp/no-image/glenn.original.jpg'
            entry.should.have.deep.property 'images[1].w320',     '/tmp/no-image/glenn.w320.jpg'
            entry.should.have.deep.property 'images[1].w640',     '/tmp/no-image/glenn.w640.jpg'
            entry.should.have.deep.property 'images[1].w1024',    '/tmp/no-image/glenn.w1024.jpg'
            done()



      # TEXT AND BODY

      it 'should set both text and html to null when no body', (done) ->
        spy = spyfs.on '/tmp/empty-body/info.txt', 'title: only'
        Entry.load spy.dirname, (err, entry) ->
          entry.should.have.property 'text', null
          entry.should.have.property 'html', null
          done()


      describe 'text property', ->
        it 'defaults to null', (done) ->
          spy = spyfs.on '/tmp/text-null/info.txt', 'title: hello'
          Entry.load spy.dirname, (err, entry) ->
            entry.should.have.property 'text', null
            done()

        it 'should handle title and several paragraphs of body', (done) ->
          spy = spyfs.on '/tmp/multi-paras/info.txt', "title: Title\n\nBody text.\n\nMore body text."
          Entry.load spy.dirname, (err, entry) ->
            entry.should.have.property 'text', 'Body text.\n\nMore body text.'
            entry.should.have.property 'title', 'Title'
            done()


      describe 'with body', ->
        entry = null
        before (done) ->
          spy = spyfs.on '/tmp/empty-body/info.txt', 'title:hej\n\nParagraph 1\n\nParagraph 2\n\nParagraph 3'
          Entry.load spy.dirname, (err, _entry) ->
            entry = _entry
            done()
        it 'should have a html property', ->
          entry.should.have.property 'html'
        it 'html property should be readonly', ->
          entry.html = "nope"
          entry.html.should.not.equal 'nope'
        it 'should have a html property with paragraphs', ->
          entry.html.should.contain '<p>Paragraph 1'
          entry.html.should.contain '<p>Paragraph 2'
          entry.html.should.contain '<p>Paragraph 3'


    describe "#description", ->
      withText = (s, cb) ->
        spy = spyfs.on '/tmp/body-vs-description/info.txt', "title:hej\n\n#{s}"
        Entry.load spy.dirname, (err, entry) -> cb entry

      it 'should have a description property', ->
        new Entry().should.have.property 'description'
      it 'description property should be readonly', ->
        entry = new Entry
        entry.text = "Text"
        entry.description = "nope"
        entry.description.should.not.equal 'nope'
      it "should strip html", (done) ->
        withText '*** bold text *** [Link title](http://www.google.com)', (entry) ->
          entry.description.should.equal 'bold text Link title'
          done()
      it "should truncate at 100 chars", (done) ->
        s = new Array(110).join 'x' # 109 long string
        withText s, (entry) ->
          entry.description.should.have.length 100
          done()



  it 'should lookup the timezone from askgeo for images (postponed, build npm package)'



  # DATE PATH

  describe "date path property", ->
    it "should default to null", ->
      entry = new Entry
      expect(entry.datePath).to.be.null

    it "should be read only", ->
      entry = new Entry
      entry.datePath = 'Nope'
      expect(entry.datePath).to.be.null

    it "should generate ok", ->
      entry = new Entry
      expect(entry.datePath).to.be.null

      entry.time = new Date(2012, 0, 1)
      entry.datePath.should.equal '2012/01/01'

      entry.time = new Date(2012, 11, 31)
      entry.datePath.should.equal '2012/12/31'



  # SUBTITLE

  describe "#subtitle", ->
    it "should exist", ->
      new Entry().should.have.property 'subtitle', null
    it "shows the age in days", ->
      entry = new Entry
      entry.time = new Date 2012, 6, 7 # 1012-07-06
      entry.should.have.property 'subtitle', '1 månad gammal'
    it "shows the time until birth", ->
      entry = new Entry
      entry.time = new Date 2012, 5, 2 # 1012-06-02
      entry.should.have.property 'subtitle', '5 dagar till födseln'



  # SLUG

  describe "#slug property", ->
    it "should exist and be null", ->
      new Entry().should.have.property 'slug', null

    it "sluggifies åäö", ->
      entry = new Entry
      entry.title = "hejsan, åäö"
      entry.slug.should.equal 'hejsan-aao'

    it "lowercases capital letters", ->
      entry = new Entry
      entry.title = "ABCabcÅÄÖÉ"
      entry.slug.should.equal 'abcabcaaoe'

    it "should remove some extra chars from title", ->
      # Allowed in node-slug module. I don't allow them.
      for char in ['*', '+', '~', '.', '(', ')', '\'', '"', '!', ':', '@']
        entry = new Entry
        entry.title = "pre #{char} post"
        entry.slug.should.equal 'pre-post'

  # PATH

  describe "#path property", ->
    it "should exist and be null", ->
      new Entry().should.have.property 'path', null

    it "ends in a slug", ->
      entry = new Entry().tap ->
        @title = "Miliam är först"
        @time  = new Date 2012, 11, 9
      entry.path.should.match /miliam-ar-forst$/

    it "combines date and slug", ->
      entry = new Entry().tap ->
        @title = "Miliam är först"
        @time  = new Date 2012, 11, 9
      entry.path.should.equal '/2012/12/09/miliam-ar-forst'

  describe "#url property", ->
    it "should exist and be null", ->
      new Entry().should.have.property 'url', null

    it "combines host and path", ->
      entry = new Entry().tap ->
        @title = "Miliam är först"
        @time  = new Date 2012, 11, 9
      entry.url.should.equal 'http://miliam.se/2012/12/09/miliam-ar-forst'


  # SERIALIZATION

  describe "#serialize", ->
    entry = 0
    beforeEach ->
      entry = new Entry
      entry.title = "Miliam går på tå"
      entry.time = new Date "2012-05-07T01:00:00+0200"
      entry.text = "Text 1\nText 2\nText 3"
      entry.images = []
      entry.images.push
        original: "image1.original.jpg"
        w320:     "image1.w320.jpg"
        w640:     "image1.w640.jpg"
        w1024:    "image1.w1024.jpg"
      entry.images.push
        original: "image2.original.jpg"
        w320:     "image2.w320.jpg"
        w640:     "image2.w640.jpg"
        w1024:    "image2.w1024.jpg"

    it "requires a title"


    it "should respond to serialize", ->
      entry.should.respondTo 'serialize'
      entry.serialize.should.have.length 0

    it "should not fail when no time is set", ->
      delete entry.time
      entry.serialize().should.not.contain 'time: '
      entry.serialize().should.not.contain 'date: '

    it "should serialize meta data", ->
      entry.serialize().should.contain "title: Miliam går på tå"
      entry.serialize().should.contain "date: 2012-05-07"
      entry.serialize().should.contain "time: 01:00:00"
      entry.serialize().should.contain "Text 1\nText 2\nText 3"

    it "should serialize image data for many images", ->
      entry.serialize().should.contain "image: image1"
      entry.serialize().should.contain "image: image2"
      entry.serialize().should.not.contain "image: image0"
      entry.serialize().should.not.contain "image: image3"
      entry.serialize().should.not.contain "image: image\n"

    it "should not serialize image data for generated images", ->
      entry.serialize().should.not.contain "image: image1.w320"
      entry.serialize().should.not.contain "image: image1.w640"
      entry.serialize().should.not.contain "image: image1.w1024"

    it "should remove 'original' if present", ->
      entry.images[0].original = "image3.original.jpg"
      entry.serialize().should.contain "image: image3\n"

    it "should do nothing if 'original' isn't present in image name", ->
      entry.images[0].original = "image3.jpg"
      entry.serialize().should.contain "image: image3\n"