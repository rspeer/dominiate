class MultiLog
  constructor: (@outputElt, @paginatorElt) ->
    @pages = []
    this.selectPage(1)
  
  reset: ->
    @pages = []
    this.selectPage(1)
    this.updateOutput()
    this.updatePaginator()
  
  numPages: -> @pages.length
  
  pagesShown: ->
    minPage = Math.max(@currentPage - 4, 1)
    maxPage = Math.min(this.numPages(), minPage + 9)
    minPage = Math.max(1, maxPage - 9)
    return [] if maxPage < minPage
    return [minPage..maxPage]
  
  getCurrent: ->
    @pages[@currentPage-1]

  updateOutput: ->
    if @pages[@currentPage-1]?
      @outputElt.html(@pages[@currentPage-1])
      window.scrollToBottom(@outputElt)
  
  prevButtonClass: ->
    if @currentPage <= 1
      "prev page disabled"
    else
      "prev page"

  nextButtonClass: ->
    if @currentPage >= this.numPages()
      "next page disabled"
    else
      "next page"

  updatePaginator: ->
    prev = "<li class='#{this.prevButtonClass()}'><a href='#'>&larr; Previous</a></li>"
    next = "<li class='#{this.nextButtonClass()}'><a href='#'>Next &rarr;</a></li>"
    items = [prev]
    for pageNum in this.pagesShown()
      if pageNum == @currentPage
        item = "<li class='active page'><a href='#'>#{pageNum}</a></li>"
      else
        item = "<li class='page'><a href='#'>#{pageNum}</a></li>"
      items.push(item)
    items.push(next)
    @paginatorElt.html('<ul>' + items.join('') + '</ul>')
    this.updateEvents()

  updateEvents: ->
    $('.page').click (event) =>
      if not $(event.currentTarget).hasClass('disabled')
        liText = $(event.currentTarget).text()
        if liText.match(/Previous/)
          this.selectPage(@currentPage - 1)
        else if liText.match(/Next/)
          this.selectPage(@currentPage + 1)
        else
          num = +($(event.currentTarget).text())
          this.selectPage(num)
      false
  
  selectPage: (num) ->
    @currentPage = num
    this.updateOutput()
    this.updatePaginator()

  addPage: (content) ->
    @pages.push(content)
    @currentPage = this.numPages()
    this.updateOutput()
    this.updatePaginator()
  
  addLineToCurrent: (text) =>
    current = this.getCurrent()
    return if not current?
    @pages[@currentPage-1] += text+'\n'

    # don't reload the output on every line; that would be ugly and slow
    @outputElt.append(text+'\n')

this.MultiLog = MultiLog
