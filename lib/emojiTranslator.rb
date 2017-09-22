module EmojiTranslator
    @emoji = {
        'heart'     => {:unicode => "\u2764", :emoji => '❤'},
        'checkmark' => {:unicode => "\u2705", :emoji => '✅'},
        'crossmark' => {:unicode => "\u274C", :emoji => '❌'},
        'one'       => {:unicode => "\uFE0F", :emoji => '1️⃣'}
    }

    def self.name_to_unicode name
        @emoji[name][:unicode]
    end

    def self.name_to_emoji name
        @emoji[name][:emoji]
    end
end
