require "rails_helper"

RSpec.describe Sessions::DistributeXp do
  let(:campaign) { create(:campaign) }
  let(:session) { create(:session, campaign: campaign, total_xp: 1000) }
  let(:pc1) { create(:character, campaign: campaign, name: "Finch", pc: true, level: 5, xp: 0) }
  let(:pc2) { create(:character, campaign: campaign, name: "Prism", pc: true, level: 3, xp: 0) }
  let(:npc) { create(:character, campaign: campaign, name: "Vulture", pc: false, xp: 0) }

  describe "#call" do
    context "with equal distribution mode" do
      it "distributes XP equally among present characters" do
        create(:attendance, session: session, character: pc1, present: true)
        create(:attendance, session: session, character: pc2, present: true)
        create(:attendance, session: session, character: npc, present: true)

        result = described_class.new(session, xp_mode: :equal, total_xp: 1000).call

        expect(result.success?).to be true
        pc1.reload
        pc2.reload
        npc.reload
        expect(pc1.attendances.find_by(session: session).xp_earned).to eq(333)
        expect(pc2.attendances.find_by(session: session).xp_earned).to eq(333)
        expect(npc.attendances.find_by(session: session).xp_earned).to eq(333)
      end

      it "only distributes to present characters" do
        create(:attendance, session: session, character: pc1, present: true)
        create(:attendance, session: session, character: pc2, present: false)

        described_class.new(session, xp_mode: :equal, total_xp: 1000).call

        pc1.reload
        pc2.reload
        expect(pc1.attendances.find_by(session: session).xp_earned).to eq(1000)
        expect(pc2.attendances.find_by(session: session).xp_earned).to eq(0)
      end

      it "handles rounding correctly" do
        create(:attendance, session: session, character: pc1, present: true)
        create(:attendance, session: session, character: pc2, present: true)
        create(:attendance, session: session, character: npc, present: true)

        described_class.new(session, xp_mode: :equal, total_xp: 1000).call

        pc1.reload
        expect(pc1.attendances.find_by(session: session).xp_earned).to eq(333)
      end
    end

    context "with attendance_based distribution mode" do
      it "gives full XP to present characters, half to absent" do
        create(:attendance, session: session, character: pc1, present: true)
        create(:attendance, session: session, character: pc2, present: false)

        described_class.new(session, xp_mode: :attendance_based, total_xp: 1000).call

        pc1.reload
        pc2.reload
        expect(pc1.attendances.find_by(session: session).xp_earned).to eq(1000)
        expect(pc2.attendances.find_by(session: session).xp_earned).to eq(500)
      end
    end

    context "with level_scaled distribution mode" do
      it "distributes XP based on character levels" do
        pc1.update_columns(level: 5, xp: 6500)
        pc2.update_columns(level: 3, xp: 900)
        pc1.reload
        pc2.reload
        
        create(:attendance, session: session, character: pc1, present: true)
        create(:attendance, session: session, character: pc2, present: true)

        described_class.new(session, xp_mode: :level_scaled, total_xp: 1000).call

        pc1.reload
        pc2.reload
        session.reload
        pc1_xp = pc1.attendances.find_by(session: session).xp_earned
        pc2_xp = pc2.attendances.find_by(session: session).xp_earned

        expect(pc1_xp).to be > pc2_xp 
        expect(pc1_xp).to eq(625)
        expect(pc2_xp).to eq(375)
        expect(pc1_xp + pc2_xp).to eq(1000)
      end

      it "handles single character" do
        create(:attendance, session: session, character: pc1, present: true)

        described_class.new(session, xp_mode: :level_scaled, total_xp: 1000).call

        pc1.reload
        expect(pc1.attendances.find_by(session: session).xp_earned).to eq(1000)
      end
    end

    context "error handling" do
      it "returns failure if session is nil" do
        result = described_class.new(nil, xp_mode: :equal, total_xp: 1000).call

        expect(result.success?).to be false
        expect(result.errors).to include("Session not found")
      end

      it "returns failure if total_xp is zero" do
        result = described_class.new(session, xp_mode: :equal, total_xp: 0).call

        expect(result.success?).to be false
        expect(result.errors).to include("No XP to distribute")
      end

      it "returns failure if xp_mode is invalid" do
        result = described_class.new(session, xp_mode: :invalid_mode, total_xp: 1000).call

        expect(result.success?).to be false
        expect(result.errors).to include("Invalid XP mode")
      end

      it "handles exceptions gracefully" do
        allow(session).to receive(:attendances).and_raise(StandardError.new("Database error"))

        result = described_class.new(session, xp_mode: :equal, total_xp: 1000).call

        expect(result.success?).to be false
        expect(result.errors.first).to include("Error distributing XP")
      end
    end

    context "automatic level calculation" do
      it "triggers level calculation when XP is distributed" do
        attendance = create(:attendance, session: session, character: pc1, present: true, xp_earned: 0)
        pc1.update!(level: 1, xp: 0)

        described_class.new(session, xp_mode: :equal, total_xp: 300).call

        pc1.reload
        attendance.reload

        pc1.clear_xp_cache!
        expect(pc1.total_xp).to eq(300)
        expect(pc1.calculated_level).to eq(2)
        expect(pc1.level).to eq(2)
      end
    end
  end
end

