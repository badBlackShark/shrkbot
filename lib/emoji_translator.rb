module EmojiTranslator
  @emoji = {
    'heart'     => { unicode: "\u2764", emoji: '❤' },
    'checkmark' => { unicode: "\u2705", emoji: '✅' },
    'crossmark' => { unicode: "\u274C", emoji: '❌' },
    '0'         => { unicode: '',       emoji: '0⃣' },
    '1'         => { unicode: '',       emoji: '1⃣' },
    '2'         => { unicode: '',       emoji: '2⃣' },
    '3'         => { unicode: '',       emoji: '3⃣' },
    '4'         => { unicode: '',       emoji: '4⃣' },
    '5'         => { unicode: '',       emoji: '5⃣' },
    '6'         => { unicode: '',       emoji: '6⃣' },
    '7'         => { unicode: '',       emoji: '7⃣' },
    '8'         => { unicode: '',       emoji: '8⃣' },
    '9'         => { unicode: '',       emoji: '9⃣' },
    '10'        => { unicode: '',       emoji: '🔟' }
  }

  def self.name_to_unicode(name)
    @emoji[name][:unicode]
  end

  def self.name_to_emoji(name)
    @emoji[name][:emoji]
  end
end
