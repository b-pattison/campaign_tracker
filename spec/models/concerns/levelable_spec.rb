require "rails_helper"

RSpec.describe Levelable, type: :concern do
  let(:campaign) { create(:campaign) }
  let(:session) { create(:session, campaign: campaign) }
  let(:character) { create(:character, campaign: campaign, level: 1, xp: 0) }

  describe "#calculated_level" do
    it "calculates level 1 for 0 XP" do
      expect(character.calculated_level).to eq(1)
    end

    it "calculates level 2 for 300 XP" do
      create(:attendance, session: session, character: character, xp_earned: 300)
      character.clear_xp_cache!
      expect(character.calculated_level).to eq(2)
    end

    it "calculates level 5 for 6500 XP" do
      create(:attendance, session: session, character: character, xp_earned: 6500)
      character.clear_xp_cache!
      expect(character.calculated_level).to eq(5)
    end

    it "caps at level 20" do
      create(:attendance, session: session, character: character, xp_earned: 500_000)
      character.clear_xp_cache!
      expect(character.calculated_level).to eq(20)
    end
  end

  describe "#xp_for_next_level" do
    it "returns XP needed for next level" do
      create(:attendance, session: session, character: character, xp_earned: 200)
      character.clear_xp_cache!
      expect(character.xp_for_next_level).to eq(100)
    end

    it "returns nil at max level" do
      character.update_columns(level: 20, xp: 355000)
      character.clear_xp_cache!
      expect(character.xp_for_next_level).to be_nil
    end
  end

  describe "#xp_progress_percentage" do
    it "calculates progress percentage" do
      create(:attendance, session: session, character: character, xp_earned: 150)
      character.clear_xp_cache!
      expect(character.xp_progress_percentage).to eq(50.0)
    end
  end

  describe "#can_level_up?" do
    it "returns true when character can level up" do
      attendance = build(:attendance, session: session, character: character, xp_earned: 300)
      attendance.save!
      character.reload
      expect(character.calculated_level).to eq(2)
      expect(character.level).to eq(2)
      expect(character.can_level_up?).to be false
      
      character.update_column(:level, 1)
      character.clear_xp_cache!
      expect(character.can_level_up?).to be true
    end

    it "returns false when at max level" do
      character.update_columns(level: 20, xp: 355000)
      character.clear_xp_cache!
      expect(character.can_level_up?).to be false
    end
  end

  describe "automatic level calculation" do
    it "updates level when XP changes via attendance" do
      create(:attendance, session: session, character: character, xp_earned: 300)
      character.reload
      expect(character.calculated_level).to eq(2)
      character.save!
      expect(character.level).to eq(2)
    end

    it "updates level when base XP changes" do
      character.xp = 300
      character.save!
      expect(character.level).to eq(2)
    end

    it "combines base XP and attendance XP" do
      character.update!(xp: 200)
      create(:attendance, session: session, character: character, xp_earned: 100)
      character.clear_xp_cache!
      expect(character.calculated_level).to eq(2)
    end
  end

  describe "#total_xp" do
    it "sums base XP and attendance XP" do
      character.update!(xp: 100)
      create(:attendance, session: session, character: character, xp_earned: 200)
      character.clear_xp_cache!
      expect(character.total_xp).to eq(300)
    end

    it "handles zero base XP" do
      character.update!(xp: 0)
      create(:attendance, session: session, character: character, xp_earned: 300)
      character.clear_xp_cache!
      expect(character.total_xp).to eq(300)
    end
  end

  describe "#clear_xp_cache!" do
    it "clears memoized values" do
      create(:attendance, session: session, character: character, xp_earned: 300)
      character.calculated_level
      character.total_xp

      character.clear_xp_cache!

      expect(character.calculated_level).to eq(2)
      expect(character.total_xp).to eq(300)
    end
  end

  describe "#level_up_message" do
    it "returns message when character can level up" do
      create(:attendance, session: session, character: character, xp_earned: 300)
      character.update_column(:level, 1)
      character.clear_xp_cache!
      expect(character.calculated_level).to eq(2)
      expect(character.level).to eq(1)
      expect(character.can_level_up?).to be true
      expect(character.level_up_message).to include("Level up!")
      expect(character.level_up_message).to include("level 1 to level 2")
    end

    it "returns nil when character cannot level up" do
      expect(character.level_up_message).to be_nil
    end
  end

  describe "edge cases" do
    it "handles multiple attendances correctly" do
      create(:attendance, session: session, character: character, xp_earned: 200)
      create(:attendance, session: session, character: character, xp_earned: 100)
      character.clear_xp_cache!
      expect(character.total_xp).to eq(300)
      expect(character.calculated_level).to eq(2)
    end

    it "handles zero XP attendances" do
      create(:attendance, session: session, character: character, xp_earned: 0)
      character.clear_xp_cache!
      expect(character.total_xp).to eq(0)
      expect(character.calculated_level).to eq(1)
    end
  end
end

