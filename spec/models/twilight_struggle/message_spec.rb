# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::Message do
  def body_text(rendered)
    rendered[:components].first[:components].map { |block| block[:content] }.join
  end

  def buttons(rendered)
    action_row = rendered[:components].find { |block| block[:type] == Bot::Discord::Components::ACTION_ROW }
    action_row ? action_row[:components] : []
  end

  let(:usa) { TwilightStruggle::Player.new(name: "Alice", flag: "🇺🇸", discord_id: "111") }
  let(:ussr) { TwilightStruggle::Player.new(name: "Bob", flag: "🇷🇺", discord_id: "222") }
  let(:report) do
    TwilightStruggle::GameReport.new(
      usa:,
      ussr:,
      winning_side: "usa",
      winning_turn: 6,
      winning_method: "defcon",
      game_code: "R1",
      game_date: "2026-07-20",
      video_urls: []
    )
  end
  let(:template) { "{winner} beat {loser} on {turn} via {method}" }
  let(:tournament_name) { "OTSL 2026" }
  let(:ping_players) { false }
  let(:message) do
    described_class.new(
      report:,
      template:,
      tournament_name:,
      ping_players:
    )
  end

  describe "#rendered" do
    subject(:rendered) { message.rendered }

    it "substitutes tokens into the body" do
      expect(body_text(rendered)).to eq("Alice beat Bob on Turn 6 via defcon")
    end

    context "with an unknown token in the template" do
      let(:template) { "{winner} claims {trophy}" }

      it "leaves it literal" do
        expect(body_text(rendered)).to eq("Alice claims {trophy}")
      end
    end

    context "result token" do
      let(:template) { "{result}" }

      context "on a usa win" do
        it "reads winner then loser" do
          expect(body_text(rendered)).to eq("🇺🇸 **Alice** (USA) beat 🇷🇺 **Bob** (USSR)")
        end
      end

      context "on a ussr win" do
        let(:report) do
          TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "ussr")
        end

        it "reads winner then loser" do
          expect(body_text(rendered)).to eq("🇷🇺 **Bob** (USSR) beat 🇺🇸 **Alice** (USA)")
        end
      end

      context "on a tie" do
        let(:report) do
          TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "tie")
        end

        it "reads usa and ussr drew, usa first" do
          expect(body_text(rendered)).to eq("🇺🇸 **Alice** (USA) and 🇷🇺 **Bob** (USSR) drew")
        end
      end

      context "when a player has no flag" do
        let(:usa) { TwilightStruggle::Player.new(name: "Alice", discord_id: "111") }

        it "has no double space where the flag would be" do
          expect(body_text(rendered)).to eq("**Alice** (USA) beat 🇷🇺 **Bob** (USSR)")
        end
      end
    end

    context "turn token" do
      let(:template) { "{turn}" }

      context "at turn 11" do
        let(:report) do
          TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_turn: 11)
        end

        it "renders Final Scoring" do
          expect(body_text(rendered)).to eq("Final Scoring")
        end
      end

      context "at turn 6" do
        let(:report) do
          TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", winning_turn: 6)
        end

        it "renders Turn 6" do
          expect(body_text(rendered)).to eq("Turn 6")
        end
      end
    end

    context "player rendering" do
      let(:template) { "{usa} {ussr}" }

      context "when ping_players is true" do
        let(:ping_players) { true }

        it "renders players as pings" do
          expect(body_text(rendered)).to eq("<@111> <@222>")
        end
      end

      context "when ping_players is false" do
        it "renders players as plain names" do
          expect(body_text(rendered)).to eq("Alice Bob")
        end
      end
    end

    context "video buttons" do
      context "with one video" do
        let(:report) do
          TwilightStruggle::GameReport.new(usa:, ussr:, winning_side: "usa", video_urls: ["https://example.com/1"])
        end

        it "labels the single button Watch" do
          expect(buttons(rendered).map { |b| b[:label] }).to eq(["Watch"])
        end
      end

      context "with three videos" do
        let(:report) do
          TwilightStruggle::GameReport.new(
            usa:,
            ussr:,
            winning_side: "usa",
            video_urls: ["https://example.com/1", "https://example.com/2", "https://example.com/3"]
          )
        end

        it "labels them Watch 1 through Watch 3" do
          expect(buttons(rendered).map { |b| b[:label] }).to eq(["Watch 1", "Watch 2", "Watch 3"])
        end
      end

      context "with no videos" do
        it "adds no buttons" do
          expect(buttons(rendered)).to eq([])
        end
      end
    end
  end

  describe "#mention_ids" do
    subject { message.mention_ids }

    context "when ping_players is false" do
      it { is_expected.to eq([]) }
    end

    context "when ping_players is true" do
      let(:ping_players) { true }

      it "returns both discord_ids" do
        expect(message.mention_ids).to eq(%w[111 222])
      end

      context "when a player has no discord_id" do
        let(:usa) { TwilightStruggle::Player.new(name: "Alice") }

        it "drops the missing one" do
          expect(message.mention_ids).to eq(["222"])
        end
      end
    end
  end
end
