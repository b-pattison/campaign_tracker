require "rails_helper"

RSpec.describe Character, type: :model do
  subject(:character) { build(:character) }

  it "is valid with valid attributes" do
    expect(character).to be_valid
  end

  it "requires a name" do
    character.name = nil
    expect(character).not_to be_valid
    expect(character.errors[:name]).to include("can't be blank")
  end

  it "requires a class_name" do
    character.class_name = nil
    expect(character).not_to be_valid
  end

  it "requires level to be between 1 and 20" do
    character.level = 0
    expect(character).not_to be_valid

    character.level = 21
    expect(character).not_to be_valid
  end

  it "defaults to pc (true)" do
    character = build(:character)
    expect(character.pc).to be true
  end

  it "can be set to npc (false)" do
    character = build(:character, pc: false)
    expect(character.pc).to be false
    expect(character).to be_valid
  end

  describe ".by_level" do
    it "orders by level desc, then name asc" do
      c1 = create(:character, level: 3, name: "Zed")
      c2 = create(:character, level: 5, name: "Ada")
      c3 = create(:character, level: 5, name: "Bea")

      expect(Character.by_level).to eq([c2, c3, c1])
    end
  end

  describe ".for_class" do
    it "filters case-insensitively by class_name" do
      wizard = create(:character, class_name: "Wizard")
      _cleric = create(:character, class_name: "Cleric")

      expect(Character.for_class("wizard")).to contain_exactly(wizard)
    end
  end
end

