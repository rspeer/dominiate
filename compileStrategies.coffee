#!/usr/bin/env coffee
fs = require 'fs'
files = fs.readdirSync './strategies'
strategies = {}
for filename in files
  suffixPos = filename.length - 7
  if filename[suffixPos...] == '.coffee'
    code = fs.readFileSync('./strategies/'+filename, 'utf-8')
    strategies[filename[...suffixPos]] = code

definition = "strategies = "+JSON.stringify(strategies)+'\n'
fs.writeFileSync('web/strategies.js', definition)

