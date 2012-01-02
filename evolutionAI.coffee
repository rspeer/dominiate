## The Evoulton AI Class.
#--------------------------
# This code can generate, mate and mutate AI players for machine learning
# It can also write out the player as a strtegey file usable in the web interface
toSource = require 'C:\\Program Files (x86)\\nodejs\\node_modules\\toSource'

exports.mutaterate = 5 # 5 = 5%

class EvoAI
        name: null
        author: "Dr. Mitchell Morris"
        gainPriority: null
        parents:"none"
        className:"EvoAI"
        
        constructor: (@name,@parents="none",fill=yes) ->
                @className = "EvoAI"
                @gainPriority = new RuleSet(fill)
                #@name = ""
                #@name += @chr(Math.floor(Math.random()*26)+@ord('a')) for z in [0..3]
                
        ord: (str) ->
                str.charCodeAt(0)
                
        chr: (num) ->
                String.fromCharCode(num)
                
        toString: () ->
                gp = @gainPriority.toString()
                """
                {
                  name: "#{@name}"
                  parents: "#{@parents}"
                  author: "#{@author}"
                  requires: []
                  gainPriority: (state, my) -> #{gp}
                  gainValue: null
                }
                """
        
        pickle: () ->
                #toSource(this)
                JSON.stringify(this)
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @name = object.name
                @parents = object.parents
                @gainPriority = new RuleSet(no)
                @gainPriority.unpickle(object.gainPriority)
                this
                
        mutate: () ->
                @gainPriority.mutate()
     
                
        mate: (other,name=null) ->
                parents = @name+"+"+other.name
                name = parents unless name?
                child = new EvoAI(name,parents,no)
                        
                myRules = @gainPriority.getRules()
                otherRules = other.gainPriority.getRules()
                numRules = if myRules.length > otherRules.length then myRules.length else otherRules.length
                for rule in [0...numRules]
                        if myRules[rule]? and otherRules[rule]?
                                switch Math.floor(Math.random()*4)
                                        when 0 then child.gainPriority.addRule(myRules[rule].copy())
                                        when 1 then child.gainPriority.addRule(otherRules[rule].copy())
                                        when 2
                                                c = new PriorityRule(no)
                                                c.cardName = myRules[rule].cardName.copy()
                                                c.condition = otherRules[rule].condition.copy() if otherRules[rule].condition?
                                                child.gainPriority.addRule(c)
                                        when 3
                                                c = new PriorityRule(no)
                                                c.cardName = otherRules[rule].cardName.copy()
                                                c.condition = myRules[rule].condition.copy() if myRules[rule].condition?
                                                child.gainPriority.addRule(c)
                                                
                        else if myRules[rule]? and not otherRules[rule]?
                                if Math.floor(Math.random()*2) == 1
                                        child.gainPriority.addRule(myRules[rule].copy())
                        else if otherRules[rule]? and not myRules[rule]?
                                if Math.floor(Math.random()*2) == 1
                                        child.gainPriority.addRule(otherRules[rule].copy())
                child
                
                
class RuleSet
        className:"RuleSet"
        rules: null
        constructor: (fill=yes) ->
                @className = "RuleSet"
                if fill
                        @rules = new Array()
                        randomnumber=Math.floor(Math.random()*100)
                        @rules.push(new PriorityRule()) for num in [1..randomnumber]
                
        toString: () ->
                ret = "      "
                strule =(rule.toString() for rule in @rules)
                ret += strule.join("\n      ")
                """
                    [
                    #{ret}
                      ]
                """
        getNumRules: () ->
                @rules.length
                
        getRules: () ->
                @rules
                
        addRule: (rule) ->
                @rules = new Array() unless @rules?
                @rules.push(rule)
                
        copy : () ->
                c = new RuleSet(no)
                c.addRule(rule.copy) for rule in @rules
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @rules = new Array()
                @rules.push(new PriorityRule(no).unpickle(rule)) for rule in object.rules
                this
                
        mutate : () ->
                for r in [0...@rules.length]
                        if Math.floor(Math.random()*100) < exports.mutaterate
                                switch Math.floor(Math.random()*4)
                                        when 0 then @rules[r].mutate()
                                        when 1 #gene duplicaton
                                                @rules.splice(r,0,@rules[r].copy())
                                                r++
                                        when 2 #gene delete
                                                @rules.splice(r,1)
                                                r--
                                        when 3 #order swap
                                                if @rules[r-1]?
                                                        temp = @rules[r]
                                                        @rules[r] = @rules[r-1]
                                                        @rules[r-1] = temp
                                                else if @rules[r+1]?
                                                        temp = @rules[r]
                                                        @rules[r] = @rules[r+1]
                                                        @rules[r+1] = temp
                                                        
class PriorityRule
        className:"PriorityRule"
        cardName: null
        condition: null
        constructor: (fill=yes) ->
                @className = "PriortyRule"
                if fill
                        @cardName = new CardNameVaule()
                        @condition = new @pickCondition() if Math.floor(Math.random()*2) == 1
                        @condition = new NegitiveCondition(@condition) if Math.floor(Math.random()*5) == 1 and @condition?
                        complicate = yes
                        factor = 4
                        while complicate and @condition?
                                if Math.floor(Math.random()*factor) == 1
                                        @condition = new ConditionBoolopCondition(@condition, @pickCondition())
                                        @condition = new NegitiveCondition(@condition) if Math.floor(Math.random()*5) == 1
                                        factor *=2
                                else
                                        complicate = no
                                
        pickCondition: () ->
                switch Math.floor(Math.random()*2)
                        when 0 then new ExpressonCompareatorExpresson()
                        when 1 then new IsCardNameInSupply()
                
        toString: () ->
                ret = "\""+@cardName+"\""
                ret += " if "+@condition.toString() if @condition?
                ret
                
        copy: () ->
                c = new PriorityRule(no)
                c.cardName = @cardName.copy()
                c.condition = @condition.copy() if @condition?
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @cardName = new CardNameVaule(no).unpickle(object.cardName)
                if object.condition?
                        switch object.condition.className
                                when "NegitiveCondition" then @condition = new NegitiveCondition(no).unpickle(object.condition)
                                when "ExpressonCompareatorExpresson" then @condition = new ExpressonCompareatorExpresson(no).unpickle(object.condition)
                                when "IsCardNameInSupply" then @condition = new IsCardNameInSupply(no).unpickle(object.condition)
                                when "ConditionBoolopCondition" then @condition = new ConditionBoolopCondition(no).unpickle(object.condition)
                                else
                                        console.log("Priority Rule - invalid condition :"+object.condition.className)
                                        return null
                this
                
        mutate: () ->
                switch Math.floor(Math.random()*8)
                        when 0 then @cardName.mutate()
                        when 1 
                                if @condition? 
                                        @condition.mutate() 
                                else
                                        @cardName.mutate()
                        when 3
                                if @condition?
                                        if @condition.className == 'NegitiveCondition'
                                                @condition = @condition.parentCondition
                                        else
                                                @condition = new NegitiveCondition(@condition) 
                                else @condition = @pickCondition()
                        when 4 
                                if @condition? 
                                        if @condition.className != "ConditionBoolopCondition" 
                                                @condition = new ConditionBoolopCondition(@condition, @pickCondition())
                                        else
                                                @condition.mutate()
                                else
                                        @condition = @pickCondition()
                        when 5
                                if @condition? 
                                        if @condition.className != "ConditionBoolopCondition" 
                                                @condition = new ConditionBoolopCondition(@pickCondition(),@condition)
                                        else
                                                @condition.mutate()
                                else
                                        @condition = @pickCondition()
                        when 6
                                if @condition? and @condition.exp1?
                                      if @condition.className == "ConditionBoolopCondition" and @condition.exp1.className != "ConditionBoolopCondition"
                                              @condition = @condition.exp2
                                else
                                        @cardName.mutate()
                        when 7
                                if @condition? and @condition.exp2?
                                      if @condition.className == "ConditionBoolopCondition" and @condition.exp2.className != "ConditionBoolopCondition"
                                              @condition = @condition.exp1
                                else
                                        @cardName.mutate()
        
class Condition
        
        
class ExpressonCompareatorExpresson extends Condition
        className:"ExpressonCompareatorExpresson"
        exp1:null
        comp:null
        exp2:null
        
        constructor: (fill=yes) ->
                @className = "ExpressonCompareatorExpresson"
                if fill
                        @exp1 = if Math.floor(Math.random()*2) == 1 then new FunctionTakeCardName() else new FunctionNoArgs()
                        @comp = new Compareator()
                        @exp2 = new NumberValue()
                
        toString: () ->
                @exp1.toString() + " "+@comp.toString()+" "+@exp2.toString()
                
        copy: () ->
                c = new ExpressonCompareatorExpresson(no)
                
                c.exp1 = @exp1.copy()
                c.comp = @comp.copy()
                c.exp2 = @exp2.copy()
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @comp = new Compareator(no).unpickle(object.comp)
                switch object.exp1.className
                        when "FunctionTakeCardName" then @exp1 = new FunctionTakeCardName(no).unpickle(object.exp1)
                        when "FunctionNoArgs" then @exp1 = new FunctionNoArgs(no).unpickle(object.exp1)
                        when "NumberValue" then @exp1 = new NumberValue(no).unpickle(object.exp1)
                        else
                                console.log("invalid expresson :"+object.exp1.className)
                                return null
                switch object.exp2.className
                        when "FunctionTakeCardName" then @exp2 = new FunctionTakeCardName(no).unpickle(object.exp2)
                        when "FunctionNoArgs" then @exp2 = new FunctionNoArgs(no).unpickle(object.exp2)
                        when "NumberValue" then @exp2 = new NumberValue(no).unpickle(object.exp2)
                        else
                                console.log("invalid expresson :"+object.exp2.className)
                                return null
                this
                
        mutate: () ->
                switch Math.floor(Math.random()*4)
                        when 0 then @exp1.mutate()
                        when 1 then @comp.mutate()
                        when 2 then @exp2.mutate()
                        when 3
                                temp = @exp1
                                @exp1 = @exp2
                                @exp2 = temp
                
               
class ConditionBoolopCondition extends Condition
        className:"ConditionBoolopCondition"
        exp1:null
        comp:null
        exp2:null
        
        constructor: (@exp1,@exp2,fill=yes) ->
                @className = "ConditionBoolopCondition"
                if fill
                        @comp = new Boolop()
                
        toString: () ->
                @exp1.toString() + " "+@comp.toString()+" "+@exp2.toString()
                
        copy: () ->
                c = new ConditionBoolopCondition(@exp1.copy(),@exp2.copy(),no)
                c.comp = @comp.copy()
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @comp = new Boolop(no).unpickle(object.comp)
                switch object.exp1.className
                        when "NegitiveCondition" then @exp1 = new NegitiveCondition(no).unpickle(object.exp1)
                        when "ExpressonCompareatorExpresson" then @exp1 = new ExpressonCompareatorExpresson(no).unpickle(object.exp1)
                        when "IsCardNameInSupply" then @exp1 = new IsCardNameInSupply(no).unpickle(object.exp1)
                        when "ConditionBoolopCondition" then @exp1 = new ConditionBoolopCondition(no).unpickle(object.exp1)
                        else
                                console.log("invalid condition :"+object.exp1.className)
                                return null
                switch object.exp2.className
                        when "NegitiveCondition" then @exp2 = new NegitiveCondition(no).unpickle(object.exp2)
                        when "ExpressonCompareatorExpresson" then @exp2 = new ExpressonCompareatorExpresson(no).unpickle(object.exp2)
                        when "IsCardNameInSupply" then @exp2 = new IsCardNameInSupply(no).unpickle(object.exp2)
                        when "ConditionBoolopCondition" then @exp2 = new ConditionBoolopCondition(no).unpickle(object.exp2)
                        else
                                console.log("invalid condition :"+object.exp2.className)
                                return null
                                
                this
                
        mutate: () ->
                switch Math.floor(Math.random()*4)
                        when 0 then @exp1.mutate()
                        when 1 then @comp.mutate()
                        when 2 then @exp2.mutate()
                        when 3
                                temp = @exp1
                                @exp1 = @exp2
                                @exp2 = temp
                        when 4
                                if @exp1.className == "ConditionBoolopCondition" and @exp1.exp1.className != "ConditionBoolopCondition"
                                      @exp1 = @exp1.exp2
                        when 5
                                if @exp2.className == "ConditionBoolopCondition" and @exp2.exp1.className != "ConditionBoolopCondition"
                                      @exp2 = @exp2.exp2
                        when 5
                                if @exp1.className == "ConditionBoolopCondition" and @exp1.exp2.className != "ConditionBoolopCondition"
                                      @exp1 = @exp1.exp1
                        when 6
                                if @exp2.className == "ConditionBoolopCondition" and @exp2.exp2.className != "ConditionBoolopCondition"
                                      @exp2 = @exp2.exp1
                        

        
class NegitiveCondition extends Condition
        className:"NegitiveCondition"
        parentCondition:null
        
        constructor: (@parentCondition=null,fill=no) ->
                @className = "NegitiveCondition"
                
        toString: () ->
                " !("+@parentCondition.toString()+") "
                
        copy: () ->
                c = new NegitiveCondition(@parentCondition.copy(),no)
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                switch object.parentCondition.className
                        when "NegitiveCondition" then @parentCondition = new NegitiveCondition(no).unpickle(object.parentCondition)
                        when "ExpressonCompareatorExpresson" then @parentCondition = new ExpressonCompareatorExpresson(no).unpickle(object.parentCondition)
                        when "IsCardNameInSupply" then @parentCondition = new IsCardNameInSupply(no).unpickle(object.parentCondition)
                        when "ConditionBoolopCondition" then @parentCondition = new ConditionBoolopCondition(no).unpickle(object.parentCondition)
                        else
                                console.log("invalid condition :"+object.parentCondition.className)
                                return null
                this
                
        mutate: () ->
                parentCondition.mutate()
        
class IsCardNameInSupply extends Condition
        className:"IsCardNameInSupply"
        allfuncs: [
                "state.supply"
        ]
        cardName:null
        functionname:""
        constructor: (fill=yes) ->
                @className = "IsCardNameInSupply"
                if fill
                        @cardName = new CardNameVaule()
                        randomnumber=Math.floor(Math.random()*@allfuncs.length)
                        @functionname = @allfuncs[randomnumber]
                
        toString: () ->
                @functionname+"[\""+@cardName+"\"]?"    
                
        copy: () ->
                c = new IsCardNameInSupply(no)
                c.cardName = @cardName.copy()
                c.functionname = @functionname
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @cardName = new CardNameVaule(no).unpickle(object.cardName)
                @functionname = object.functionname
                this
                
        mutate: () ->
               @cardName.mutate()

class Compareator
        className: "Compareator"
        op: ""
        allops: [
                "is"
                "isnt"
                "<"
                "<="
                ">="
                ">"
        ]
        
        constructor: (fill=yes) ->
                @className = "Compareator"
                if fill
                        randomnumber=Math.floor(Math.random()*@allops.length)
                        @op = @allops[randomnumber]
                
        toString: () ->
                @op
                
        copy: () ->
                c = new Compareator(no)
                c.op = @op
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @op = object.op
                this
                
        mutate: () ->
                randomnumber=Math.floor(Math.random()*@allops.length)
                @op = @allops[randomnumber]
                
        
class Boolop
        className:"Boolop"
        op: ""
        allops: [
                "and"
                "or"
        ]
        
        constructor: (fill=yes) ->
                @className = "Boolop"
                if fill
                        randomnumber=Math.floor(Math.random()*@allops.length)
                        @op = @allops[randomnumber]
                
        toString: () ->
                @op
                
        copy: () ->
                c = new Boolop(no)
                c.op = @op
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @op = object.op
                this
         
        mutate: () ->
                randomnumber=Math.floor(Math.random()*@allops.length)
                @op = @allops[randomnumber]
                
class Expresson
        
class CardNameVaule
        cassName:"CardNameVaule"
        cardlist: ["Adventurer", "Alchemist", "Ambassador", "Apothecary", "Apprentice", "Bag of Gold", "Bank", "Baron", "Bazaar", "Bishop", "Border Village", "Bridge", "Bureaucrat", "Cache", "Caravan", "Cartographer", "Cellar", "Chancellor", "Chapel", "City", "Colony", "Conspirator", "Copper", "Coppersmith", "Council Room", "Counting House", "Courtyard", "Crossroads", "Curse", "Cutpurse", "Diadem", "Duchess", "Duchy", "Duke", "Embassy", "Envoy", "Estate", "Expand", "Explorer", "Fairgrounds", "Familiar", "Farming Village", "Farmland", "Feast", "Festival", "Fishing Village", "Followers", "Fool's Gold", "Fortune Teller", "Gardens", "Ghost Ship", "Golem", "Goons", "Grand Market", "Great Hall", "Haggler", "Hamlet", "Harem", "Haven", "Herbalist", "Highway", "Hoard", "Horn of Plenty", "Horse Traders", "Hunting Party", "Ill-Gotten Gains", "Ironworks", "Island", "Jack of All Trades", "Jester", "King's Court", "Laboratory", "Library", "Lighthouse", "Loan", "Lookout", "Mandarin", "Market", "Margrave", "Masquerade", "Menagerie", "Merchant Ship", "Militia", "Mine", "Mining Village", "Minion", "Mint", "Moat", "Monument", "Moneylender", "Mountebank", "Navigator", "Noble Brigand", "Nobles", "Nomad Camp", "Oasis", "Oracle", "Outpost", "Pawn", "Pearl Diver", "Peddler", "Philosopher's Stone", "Pirate Ship", "Platinum", "Potion", "Princess", "Province", "Quarry", "Rabble", "Remake", "Remodel", "Royal Seal", "Saboteur", "Salvager", "Scout", "Scrying Pool", "Sea Hag", "Secret Chamber", "Shanty Town", "Silk Road", "Silver", "Smithy", "Smugglers", "Spice Merchant", "Spy", "Stables", "Steward", "Tactician", "Talisman", "Thief", "Throne Room", "Torturer", "Tournament", "Trade Route", "Trader", "Trading Post", "Transmute", "Treasure Map", "Treasury", "Tribute", "Trusty Steed", "Tunnel", "University", "Upgrade", "Vault", "Venture", "Village", "Vineyard", "Walled Village", "Warehouse", "Watchtower", "Wharf", "Wishing Well", "Witch", "Woodcutter", "Worker's Village", "Workshop", "Young Witch"]
        cardName:""
        
        constructor: (fill=yes) ->
                @className = "CardNameVaule"
                if fill
                        randomnumber=Math.floor(Math.random()*@cardlist.length)
                        @cardName = @cardlist[randomnumber]
        toString: () ->
                @cardName
                
        copy: () ->
                c = new CardNameVaule(no)
                c.cardName = @cardName
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @cardName= object.cardName
                this
                
        mutate: () ->
                randomnumber=Math.floor(Math.random()*@cardlist.length)
                @cardName = @cardlist[randomnumber]
                        
        
class NumberValue extends Expresson
        className:"NumberValue"
        num:0
        
        constructor: (fill=yes) ->
                @className = "NumberValue"
                if fill
                        @num=Math.floor(Math.random()*100)
                
        toString: () ->
                ""+@num
                
        copy: () ->
               c = new NumberValue(no)
               c.num = @num
               c
               
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @num = object.num
                this
       
       mutate: () ->
               @num=Math.floor(Math.random()*100)
               
        
class FunctionNoArgs extends Expresson
        className:"FunctionNoArgs"
        functionname: null
        allfuncs: [
                "my.numCardsInDeck()"
                "my.getVP()"
                "my.getTotalMoney()"
                "my.getAvailableMoney()"
                "my.getTreasureInHand()"
                "my.numActionCardsInDeck()"
                "my.getActionDensity()"
                "my.menagerieDraws()"
                "my.shantyTownDraws(true)"
                "my.actionBalance()"
                "my.deckActionBalance()"
                "my.trashingInHand()"
                "my.numUniqueCardsInPlay()"
                "state.numEmptyPiles()"
                "state.totalPilesToEndGame()"
                "state.gainsToEndGame()"
                "state.countTotalCards()"
        ]
        
        constructor: (fill=yes) ->
                @className = "FunctionNoArgs"
                if fill
                        randomnumber=Math.floor(Math.random()*@allfuncs.length)
                        @functionname = @allfuncs[randomnumber]
        
        toString: () ->
                @functionname
        
        copy: () ->
                c = new FunctionNoArgs(no)
                c.functionname = @functionname
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @functionname = object.functionname
                this
                
        mutate: () ->
                randomnumber=Math.floor(Math.random()*@allfuncs.length)
                @functionname = @allfuncs[randomnumber]
                
                
class FunctionTakeCardName extends Expresson
        className:"FunctionTakeCardName"
        allfuncs: [
                "my.countInDeck"
                "my.countInHand"
                "my.countInDiscard"
                "my.countInPlay"
                "state.countInSupply"
        ]
        cardName:null
        functionname:""
        constructor: (fill=yes) ->
                @className = "FunctionTakeCardName"
                if fill
                        @cardName = new CardNameVaule()
                        randomnumber=Math.floor(Math.random()*@allfuncs.length)
                        @functionname = @allfuncs[randomnumber]
                
        toString: () ->
                @functionname+"(\""+@cardName+"\")"
                
        copy: () ->
                c = new FunctionTakeCardName(no)
                c.cardName = @cardName.copy()
                c.functionname = @functionname
                c
                
        unpickle: (object) ->
                if object.className != @className
                        console.log("unpickle error: 'Wrong Class Name'; Expected #{@className} got #{object.className} instead")
                        return null
                @cardName = new CardNameVaule(no).unpickle(object.cardName)
                @functionname = object.functionname
                this
                
        mutate: () ->
                switch Math.floor(Math.random()*2)
                        when 0 then @cardName.mutate()
                        when 1
                                randomnumber=Math.floor(Math.random()*@allfuncs.length)
                                @functionname = @allfuncs[randomnumber]
                        
                
this.EvoAI = EvoAI
