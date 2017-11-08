# Since the libraries I found online don't work as well as I want them to,
# I decided to just manually translate the emojis I need.
module Emojis
  @emoji = {
    'heart'     => { unicode: "\u2764",        emoji: '❤' },
    'checkmark' => { unicode: "\u2705",        emoji: '✅' },
    'crossmark' => { unicode: "\u274C",        emoji: '❌' },
    '0'         => { unicode: "\u0030\u20E3",  emoji: '0⃣' },
    '1'         => { unicode: "\u0031\u20E3",  emoji: '1⃣' },
    '2'         => { unicode: "\u0032\u20E3",  emoji: '2⃣' },
    '3'         => { unicode: "\u0033\u20E3",  emoji: '3⃣' },
    '4'         => { unicode: "\u0034\u20E3",  emoji: '4⃣' },
    '5'         => { unicode: "\u0035\u20E3",  emoji: '5⃣' },
    '6'         => { unicode: "\u0036\u20E3",  emoji: '6⃣' },
    '7'         => { unicode: "\u0037\u20E3",  emoji: '7⃣' },
    '8'         => { unicode: "\u0038\u20E3",  emoji: '8⃣' },
    '9'         => { unicode: "\u0039\u20E3",  emoji: '9⃣' },
    '10'        => { unicode: "\u1F51F",       emoji: '🔟' },
    'a'         => { unicode: "\u1F1E6",       emoji: '🇦' },
    'b'         => { unicode: "\u1F1E7",       emoji: '🇧' },
    'c'         => { unicode: "\u1F1E8",       emoji: '🇨' },
    'd'         => { unicode: "\u1F1E9",       emoji: '🇩' },
    'e'         => { unicode: "\u1F1EA",       emoji: '🇪' },
    'f'         => { unicode: "\u1F1EB",       emoji: '🇫' }
  }

  def self.name_to_unicode(name)
    @emoji[name][:unicode]
  end

  def self.name_to_emoji(name)
    @emoji[name][:emoji]
  end
end
