# Since the libraries I found online don"t work as well as I want them to,
# I decided to just manually translate the emojis I need.
module Utilities
  class Emojis
    @@emoji = {
      "0"       => {unicode: "\u0030\u20E3", emoji: "0⃣"},
      "1"       => {unicode: "\u0031\u20E3", emoji: "1⃣"},
      "2"       => {unicode: "\u0032\u20E3", emoji: "2⃣"},
      "3"       => {unicode: "\u0033\u20E3", emoji: "3⃣"},
      "4"       => {unicode: "\u0034\u20E3", emoji: "4⃣"},
      "5"       => {unicode: "\u0035\u20E3", emoji: "5⃣"},
      "6"       => {unicode: "\u0036\u20E3", emoji: "6⃣"},
      "7"       => {unicode: "\u0037\u20E3", emoji: "7⃣"},
      "8"       => {unicode: "\u0038\u20E3", emoji: "8⃣"},
      "9"       => {unicode: "\u0039\u20E3", emoji: "9⃣"},
      "10"      => {unicode: "\u{1F51F}", emoji: "🔟"},
      "a"       => {unicode: "\u{1F1E6}", emoji: "🇦"},
      "b"       => {unicode: "\u{1F1E7}", emoji: "🇧"},
      "c"       => {unicode: "\u{1F1E8}", emoji: "🇨"},
      "d"       => {unicode: "\u{1F1E9}", emoji: "🇩"},
      "e"       => {unicode: "\u{1F1EA}", emoji: "🇪"},
      "f"       => {unicode: "\u{1F1EB}", emoji: "🇫"},
      "g"       => {unicode: "\u{1F1EC}", emoji: "🇬"},
      "h"       => {unicode: "\u{1F1ED}", emoji: "🇭"},
      "i"       => {unicode: "\u{1F1EE}", emoji: "🇮"},
      "j"       => {unicode: "\u{1F1EF}", emoji: "🇯"},
      "k"       => {unicode: "\u{1F1F0}", emoji: "🇰"},
      "l"       => {unicode: "\u{1F1F1}", emoji: "🇱"},
      "m"       => {unicode: "\u{1F1F2}", emoji: "🇲"},
      "n"       => {unicode: "\u{1F1F3}", emoji: "🇳"},
      "o"       => {unicode: "\u{1F1F4}", emoji: "🇴"},
      "p"       => {unicode: "\u{1F1F5}", emoji: "🇵"},
      "q"       => {unicode: "\u{1F1F6}", emoji: "🇶"},
      "r"       => {unicode: "\u{1F1F7}", emoji: "🇷"},
      "s"       => {unicode: "\u{1F1F8}", emoji: "🇸"},
      "t"       => {unicode: "\u{1F1F9}", emoji: "🇹"},
      "u"       => {unicode: "\u{1F1FA}", emoji: "🇺"},
      "v"       => {unicode: "\u{1F1FB}", emoji: "🇻"},
      "w"       => {unicode: "\u{1F1FC}", emoji: "🇼"},
      "x"       => {unicode: "\u{1F1FD}", emoji: "🇽"},
      "y"       => {unicode: "\u{1F1FE}", emoji: "🇾"},
      "z"       => {unicode: "\u{1F1FF}", emoji: "🇿"},
      "refresh" => {unicode: "\u{1F504}", emoji: "🔄"},
    }

    def self.name_to_unicode(name : String)
      URI.encode(@@emoji[name][:unicode])
    end

    def self.name_to_emoji(name)
      @@emoji[name][:emoji]
    end
  end
end
