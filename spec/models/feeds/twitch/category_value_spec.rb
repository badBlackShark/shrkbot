# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::CategoryValue do
  let(:category) { {"id" => "27471", "name" => "Minecraft"} }

  describe ".dump" do
    it "pins the key order the JS side relies on" do
      expect(described_class.dump({"id" => "1", "name" => "Hades II"})).to eq('{"id":"1","name":"Hades II"}')
    end

    it "writes the id before the name" do
      expect(described_class.dump({"name" => "Minecraft", "id" => "27471"})).to eq('{"id":"27471","name":"Minecraft"}')
    end
  end

  describe ".parse" do
    it "reads back what dump wrote" do
      expect(described_class.parse(described_class.dump(category))).to eq(category)
    end

    it "keeps only the id and the name" do
      expect(described_class.parse('{"id":"1","name":"A","extra":true}')).to eq("id" => "1", "name" => "A")
    end

    it "is nil for text that is not JSON" do
      expect(described_class.parse("garbage")).to be_nil
    end

    it "is nil for an object with a numeric id" do
      expect(described_class.parse('{"id":1,"name":"x"}')).to be_nil
    end

    it "is nil for an empty object" do
      expect(described_class.parse("{}")).to be_nil
    end

    it "is nil for JSON that is not an object" do
      expect(described_class.parse("[1]")).to be_nil
    end
  end

  describe ".valid?" do
    it "accepts a string id with a string name" do
      expect(described_class.valid?(category)).to be(true)
    end

    [
      [{"id" => 1, "name" => "x"}, "a numeric id"],
      [{"id" => "", "name" => "x"}, "a blank id"],
      [{"id" => "1", "name" => nil}, "a missing name"],
      [["1"], "a non-hash"]
    ].each do |value, description|
      it "rejects #{description}" do
        expect(described_class.valid?(value)).to be(false)
      end
    end
  end

  describe ".parse_all" do
    let(:values) { [described_class.dump(category), "garbage", '{"id":1,"name":"x"}', "{}", described_class.dump({"id" => "27471", "name" => "Again"})] }

    it "drops garbage and duplicates by id" do
      expect(described_class.parse_all(values)).to eq([category])
    end
  end
end
