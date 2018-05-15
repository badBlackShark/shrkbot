# Translates icon names to their URLs
module Icons
  @icons = {
    revolver_0:  'https://i.imgur.com/4HQn3bM.png',
    revolver_1:  'https://i.imgur.com/5ZgJAHr.png',
    revolver_2:  'https://i.imgur.com/PWbR8im.png',
    revolver_3:  'https://i.imgur.com/xoqSRXB.png',
    revolver_4:  'https://i.imgur.com/hohi0Eb.png',
    revolver_5:  'https://i.imgur.com/YZQQhYr.png',
    revolver_d1: 'https://i.imgur.com/XoNJIqb.png',
    revolver_d2: 'https://i.imgur.com/tbWKfUU.png',
    revolver_d3: 'https://i.imgur.com/WQPmdN9.png',
    revolver_d4: 'https://i.imgur.com/s2MmQeH.png',
    revolver_d5: 'https://i.imgur.com/ZhunMlP.png',
    revolver_d6: 'https://i.imgur.com/13XaqwC.png',
    leaderboard: 'https://i.imgur.com/YRpyB3Z.png',
    chart:       'https://i.imgur.com/PDWjYaj.png',
    heart:       'https://i.imgur.com/eB4sDct.png'
  }.freeze

  def self.name_to_link(name)
    @icons[name] || name
  end
end
