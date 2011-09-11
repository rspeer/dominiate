(function() {
  var MultiLog;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  MultiLog = (function() {
    function MultiLog(outputElt, paginatorElt) {
      this.outputElt = outputElt;
      this.paginatorElt = paginatorElt;
      this.addLineToEnd = __bind(this.addLineToEnd, this);
      this.addLineToCurrent = __bind(this.addLineToCurrent, this);
      this.pages = [];
      this.selectPage(1);
    }
    MultiLog.prototype.reset = function() {
      this.pages = [];
      this.selectPage(1);
      this.updateOutput();
      return this.updatePaginator();
    };
    MultiLog.prototype.numPages = function() {
      return this.pages.length;
    };
    MultiLog.prototype.pagesShown = function() {
      var maxPage, minPage, _i, _results;
      minPage = Math.max(this.currentPage - 4, 1);
      maxPage = Math.min(this.numPages(), minPage + 9);
      minPage = Math.max(1, maxPage - 9);
      if (maxPage < minPage) {
        return [];
      }
      return (function() {
        _results = [];
        for (var _i = minPage; minPage <= maxPage ? _i <= maxPage : _i >= maxPage; minPage <= maxPage ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this);
    };
    MultiLog.prototype.getCurrent = function() {
      return this.pages[this.currentPage - 1];
    };
    MultiLog.prototype.updateOutput = function() {
      if (this.pages[this.currentPage - 1] != null) {
        this.outputElt.html(this.pages[this.currentPage - 1]);
        return window.scrollToBottom(this.outputElt);
      }
    };
    MultiLog.prototype.prevButtonClass = function() {
      if (this.currentPage <= 1) {
        return "prev page disabled";
      } else {
        return "prev page";
      }
    };
    MultiLog.prototype.nextButtonClass = function() {
      if (this.currentPage >= this.numPages()) {
        return "next page disabled";
      } else {
        return "next page";
      }
    };
    MultiLog.prototype.updatePaginator = function() {
      var item, items, next, pageNum, prev, _i, _len, _ref;
      prev = "<li class='" + (this.prevButtonClass()) + "'><a href='#'>&larr; Previous</a></li>";
      next = "<li class='" + (this.nextButtonClass()) + "'><a href='#'>Next &rarr;</a></li>";
      items = [prev];
      _ref = this.pagesShown();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pageNum = _ref[_i];
        if (pageNum === this.currentPage) {
          item = "<li class='active page'><a href='#'>" + pageNum + "</a></li>";
        } else {
          item = "<li class='page'><a href='#'>" + pageNum + "</a></li>";
        }
        items.push(item);
      }
      items.push(next);
      this.paginatorElt.html('<ul>' + items.join('') + '</ul>');
      return this.updateEvents();
    };
    MultiLog.prototype.updateEvents = function() {
      return $('.page').click(__bind(function(event) {
        var liText, num;
        if (!$(event.currentTarget).hasClass('disabled')) {
          liText = $(event.currentTarget).text();
          if (liText.match(/Previous/)) {
            this.selectPage(this.currentPage - 1);
          } else if (liText.match(/Next/)) {
            this.selectPage(this.currentPage + 1);
          } else {
            num = +($(event.currentTarget).text());
            this.selectPage(num);
          }
        }
        return false;
      }, this));
    };
    MultiLog.prototype.selectPage = function(num) {
      this.currentPage = num;
      this.updateOutput();
      return this.updatePaginator();
    };
    MultiLog.prototype.addPage = function(content) {
      if (this.pages.length >= 100) {
        this.pages = this.pages.slice(50);
      }
      this.pages.push(content);
      this.currentPage = this.numPages();
      this.updateOutput();
      return this.updatePaginator();
    };
    MultiLog.prototype.addPageQuietly = function(content) {
      if (this.pages.length > 100) {
        this.pages = this.pages.slice(50);
        this.updateOutput();
      }
      this.pages.push(content);
      return this.updatePaginator();
    };
    MultiLog.prototype.addLineToCurrent = function(text) {
      var current;
      current = this.getCurrent();
      if (!(current != null)) {
        return;
      }
      this.pages[this.currentPage - 1] += text + '\n';
      return this.outputElt.append(text + '\n');
    };
    MultiLog.prototype.addLineToEnd = function(text) {
      var current;
      current = this.getCurrent();
      if (!(current != null)) {
        return;
      }
      this.pages[this.pages.length - 1] += text + '\n';
      if (this.currentPage === this.pages.length - 1) {
        return this.outputElt.append(text + '\n');
      }
    };
    return MultiLog;
  })();
  this.MultiLog = MultiLog;
}).call(this);
