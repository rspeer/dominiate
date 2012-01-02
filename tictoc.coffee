class TicToc
        start: 0
        constructor: () ->
                @start = 0
        tic: () ->
                @start = new Date().getTime()
                
        toc: () ->
                end = new Date().getTime()
                time = end - @start
                
        tocString: () ->
                end = new Date().getTime()
                time = end - @start
                if time < 1000
                        return ""+time+" Miliseconds"
                else if time < 1000*90
                        return ""+time/1000+" Seconds"
                else if time < 1000*60*60
                        return ""+time/1000/60+" Minutes"
                else
                        return ""+time/1000/60/60+" Hours"
                
this.TicToc = TicToc
