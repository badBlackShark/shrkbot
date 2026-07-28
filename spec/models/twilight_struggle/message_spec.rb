# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Message do
  let(:usa) { TwilightStruggle::Player.new(name: "M B", flag: "🇵🇱", discord_id: "111") }
  let(:ussr) { TwilightStruggle::Player.new(name: "L S", flag: "🇦🇷", discord_id: "222") }
  let(:report) do
    TwilightStruggle::GameReport.new(
      usa:,
      ussr:,
      winning_side: "usa",
      winning_turn: 7,
      winning_method: "VP Track (+20)",
      game_code: "G372",
      video_urls: []
    )
  end
  let(:template) { "{winning_player} beat {losing_player} on {turn} via {winning_method}" }
  let(:tournament_name) { "OTSL 2026 - Season 8" }
  let(:ping_players) { false }
  let(:message) do
    described_class.new(
      report:,
      template:,
      tournament_name:,
      ping_players:
    )
  end

  describe "#content" do
    subject(:content) { message.content }

    context "win template shape" do
      let(:template) { "{tournament_name}: {game_id} - {winning_player} ({winning_side}) has defeated {losing_player} in {turn} ({winning_method})" }

      it "matches the site's result phrasing" do
        expect(content).to eq("OTSL 2026 - Season 8: G372 - M B 🇵🇱 (USA) has defeated L S 🇦🇷 in Turn 7 (VP Track (+20))")
      end
    end

    context "tie template shape" do
      let(:template) { "{tournament_name}: {game_id} - {usa_player} (USA) tied with {ussr_player} in {turn} ({winning_method})" }
      let(:report) do
        TwilightStruggle::GameReport.new(
          usa: TwilightStruggle::Player.new(name: "M N", flag: "🇦🇩", discord_id: "111"),
          ussr: TwilightStruggle::Player.new(name: "D C", flag: "🇰🇷", discord_id: "222"),
          winning_side: "tie",
          winning_turn: 10,
          winning_method: "Wargames",
          game_code: "C204"
        )
      end
      let(:tournament_name) { "RATS Cup 2026" }

      it "matches the site's tie phrasing" do
        expect(content).to eq("RATS Cup 2026: C204 - M N 🇦🇩 (USA) tied with D C 🇰🇷 in Turn 10 (Wargames)")
      end

      context "when tags are on and the template asks for a winner there is not" do
        let(:template) { "{winning_player}|{winning_name}" }
        let(:ping_players) { true }

        it "renders empty rather than a stray tag" do
          expect(content).to eq("|")
        end
      end
    end

    context "video template shape" do
      let(:template) { "{tournament_name}: {game_id} - {usa_player} vs {ussr_player} {videos}" }
      let(:report) do
        TwilightStruggle::GameReport.new(
          usa: TwilightStruggle::Player.new(name: "T B", flag: "🇵🇱", discord_id: "111"),
          ussr: TwilightStruggle::Player.new(name: "A S", flag: "🇸🇪", discord_id: "222"),
          winning_side: "usa",
          winning_turn: 5,
          winning_method: "defcon",
          game_code: "S378",
          video_urls: ["https://youtu.be/videolink"]
        )
      end
      let(:tournament_name) { "OTSL 2026 - Season 8" }

      it "is spoiler-free, no winner or turn or method leaking through" do
        expect(content).to eq("OTSL 2026 - Season 8: S378 - T B 🇵🇱 vs A S 🇸🇪 https://youtu.be/videolink")
      end
    end

    context "with an unknown token in the template" do
      let(:template) { "{winning_player} claims {trophy}" }

      it "leaves it literal" do
        expect(content).to eq("M B 🇵🇱 claims {trophy}")
      end
    end

    context "player token" do
      let(:template) { "{usa_player}" }

      context "when the player has no flag" do
        let(:usa) { TwilightStruggle::Player.new(name: "M B", discord_id: "111") }

        it "has no trailing or doubled space" do
          expect(content).to eq("M B")
        end
      end

      context "when ping_players is true" do
        let(:ping_players) { true }

        it "keeps the real name and appends the tag after the flag" do
          expect(content).to eq("M B 🇵🇱 (<@111>)")
        end

        context "when the player has no discord_id" do
          let(:usa) { TwilightStruggle::Player.new(name: "M B", flag: "🇵🇱") }

          it "renders the name alone, with no empty brackets" do
            expect(content).to eq("M B 🇵🇱")
          end
        end
      end

      context "when ping_players is false" do
        it "renders the plain name followed by the flag" do
          expect(content).to eq("M B 🇵🇱")
        end
      end
    end

    context "turn token" do
      let(:template) { "{turn}" }

      context "at turn 11" do
        let(:report) { TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_turn: 11) }

        it "renders Final Scoring" do
          expect(content).to eq("Final Scoring")
        end
      end

      context "at turn 6" do
        let(:report) { TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_turn: 6) }

        it "renders Turn 6" do
          expect(content).to eq("Turn 6")
        end
      end

      context "when nil" do
        let(:report) { TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_turn: nil) }

        it "renders empty" do
          expect(content).to eq("")
        end
      end
    end

    context "winning method token" do
      let(:template) { "{winning_method}" }

      context "when sent" do
        let(:report) { TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_method: "Wargames") }

        it "renders it as sent" do
          expect(content).to eq("Wargames")
        end
      end

      context "when nil" do
        let(:report) { TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_method: nil) }

        it "renders empty" do
          expect(content).to eq("")
        end
      end

      context "when nil in the default win template" do
        let(:template) { "{tournament_name}: {game_id} - {winning_player} ({winning_side}) has defeated {losing_player} in {turn} ({winning_method})" }
        let(:report) do
          TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_turn: 7, game_code: "G372")
        end

        it "leaves the parentheses the template author wrote" do
          expect(content).to eq("OTSL 2026 - Season 8: G372 - M B 🇵🇱 (USA) has defeated L S 🇦🇷 in Turn 7 ()")
        end
      end
    end

    context "on a tie" do
      let(:template) { "[{winning_player}][{losing_player}][{winning_side}][{losing_side}]" }
      let(:report) { TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "tie") }

      it "leaves the winner/loser tokens empty without a conditional at the call site" do
        expect(content).to eq("[][][][]")
      end
    end

    context "videos token" do
      let(:template) { "{videos}" }

      context "with multiple urls" do
        let(:report) do
          TwilightStruggle::GameReport.new(
            usa:,
            ussr:,
            winning_side: "usa",
            video_urls: ["https://example.com/1", "https://example.com/2"]
          )
        end

        it "joins them with a single space" do
          expect(content).to eq("https://example.com/1 https://example.com/2")
        end
      end

      context "with no urls" do
        it "is empty" do
          expect(content).to eq("")
        end
      end
    end
  end
end
