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
        debugger
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
            spy = spyfs.on '/tmp/human-time/info.txt', 'date: 2012-06-06\ntime: 10:14'
            Entry.load Path.dirname(spy.path), (err, _entry) ->
              entry = _entry
              done()
          it 'has a pretty date prop', ->
            entry.should.have.property 'humanDate', "6 jun 2012"
          it 'has a pretty date prop', ->
            entry.should.have.property 'humanTime', "10:14"
          it 'is readonly', ->
            entry.humanTime = 'nope'
            entry.humanDate = 'nope'
            entry.should.have.property 'humanTime', "10:14"
            entry.should.have.property 'humanDate', "6 jun 2012"







      # IMAGE INFO

      describe 'with image meta data', ->
        it 'should be null when no images', (done) ->
          spy = spyfs.on '/tmp/no-image/info.txt', 'title: only'
          Entry.load spy.dirname, (err, entry) ->
            entry.should.have.property 'images', null
            done()

        it 'should have image props', (done) ->
          spy = spyfs.on '/tmp/no-image/info.txt', 'image: image1'
          Entry.load spy.dirname, images: true, (err, entry) ->
            entry.should.have.deep.property 'images[0].w320',  '/tmp/no-image/image1.w320.jpg'
            entry.should.have.deep.property 'images[0].w640',  '/tmp/no-image/image1.w640.jpg'
            entry.should.have.deep.property 'images[0].w1024', '/tmp/no-image/image1.w1024.jpg'
            done()

        it 'should have props for multiple images', (done) ->
          spy = spyfs.on '/tmp/no-image/info.txt', 'image: sia\nimage: glenn'
          Entry.load spy.dirname, images: true, (err, entry) ->
            entry.should.have.deep.property 'images[0].w320',  '/tmp/no-image/sia.w320.jpg'
            entry.should.have.deep.property 'images[0].w640',  '/tmp/no-image/sia.w640.jpg'
            entry.should.have.deep.property 'images[0].w1024', '/tmp/no-image/sia.w1024.jpg'
            entry.should.have.deep.property 'images[1].w320',  '/tmp/no-image/glenn.w320.jpg'
            entry.should.have.deep.property 'images[1].w640',  '/tmp/no-image/glenn.w640.jpg'
            entry.should.have.deep.property 'images[1].w1024', '/tmp/no-image/glenn.w1024.jpg'
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



  it 'should lookup the timezone from askgeo for images (postponed, build npm package)'


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
