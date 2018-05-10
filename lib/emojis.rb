# Since the libraries I found online don't work as well as I want them to,
# I decided to just manually translate the emojis I need.
module Emojis
  @emoji = {
    'heart'     => { unicode: "\u2764",        emoji: '❤' },
    'checkmark' => { unicode: "\u2705",        emoji: '✅' },
    'crossmark' => { unicode: "\u274C",        emoji: '❌' },
    'thumbs_up' => { unicode: "\u1F44D",       emoji: '👍' },
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
    'f'         => { unicode: "\u1F1EB",       emoji: '🇫' },
    'g'         => { unicode: "\u1F1EC",       emoji: '🇬' },
    'h'         => { unicode: "\u1F1ED",       emoji: '🇭' },
    'i'         => { unicode: "\u1F1EE",       emoji: '🇮' },
    'j'         => { unicode: "\u1F1EF",       emoji: '🇯' },
    'k'         => { unicode: "\u1F1F0",       emoji: '🇰' },
    'l'         => { unicode: "\u1F1F1",       emoji: '🇱' },
    'm'         => { unicode: "\u1F1F2",       emoji: '🇲' },
    'n'         => { unicode: "\u1F1F3",       emoji: '🇳' },
    'o'         => { unicode: "\u1F1F4",       emoji: '🇴' },
    'p'         => { unicode: "\u1F1F5",       emoji: '🇵' },
    'q'         => { unicode: "\u1F1F6",       emoji: '🇶' },
    'r'         => { unicode: "\u1F1F7",       emoji: '🇷' },
    's'         => { unicode: "\u1F1F8",       emoji: '🇸' },
    't'         => { unicode: "\u1F1F9",       emoji: '🇹' },
    'u'         => { unicode: "\u1F1FA",       emoji: '🇺' },
    'v'         => { unicode: "\u1F1FB",       emoji: '🇻' },
    'w'         => { unicode: "\u1F1FC",       emoji: '🇼' },
    'x'         => { unicode: "\u1F1FD",       emoji: '🇽' },
    'y'         => { unicode: "\u1F1FE",       emoji: '🇾' },
    'z'         => { unicode: "\u1F1FF",       emoji: '🇿' }
  }

  def self.name_to_unicode(name)
    @emoji[name][:unicode] || name
  end

  def self.name_to_emoji(name)
    @emoji[name][:emoji] || name
  end
end
