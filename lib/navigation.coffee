sprintf = require('sprintf').sprintf

short_months = ' J F M A M J J A S O N D'.split ' '
long_months = ' Januari Februari Mars April Maj Juni Juli Augusti September Oktober November December'.split ' '

fixture =
  2011: [ 12 ]
  2012: [ 4, 6, 7, 8, 9, 10, 11, 12 ]
  2013: [ 1..12 ]
  2014: [ 1..12 ]
  2015: [ 1..12 ]

d2s = (y, m) -> sprintf "%04d-%02d", y, m

now = new Date()
snow = d2s now.getFullYear(), now.getMonth() + 1

data = {}

for year in [2011..2020] when year <= now.getFullYear()
  for month in [1..12]
    current = d2s year, month
    data[year] = [] unless data[year]
    data[year].push
      short: short_months[month]
      long: long_months[month]
      path: sprintf "/%04d/%02d", year, month
      # show a link if year is 2013+, we expect to post at least once a month until further notice
      # show link if 2011 or 2012 if the fixture contain info about it
      # but hide link if it is in the future
      link: fixture[year].indexOf(month) >= 0 and current <= snow

module.exports = data