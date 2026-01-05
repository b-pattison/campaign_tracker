require "rails_helper"

RSpec.describe Sessions::Finalize do
    describe "#call!" do
        it "marks the session played" do
            campaign = create(:campaign)
            session = create(:session, campaign:, status: "planned", xp_mode:"split", scheduled_at: Time.current, total_xp: 10)

            Sessions::Finalize.new(session).call!

            expect(session.reload.status).to eq("played")
            expect(session.played_at).to be_present
        end

        context "split mode" do
            it "splits total_xp across present PCs only" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "split", total_xp: 10)

                pc1 = create(:character, campaign: campaign, name: "Finch", pc: true)
                pc2 = create(:character, campaign: campaign, name: "Raphael", pc: true)
                pc3 = create(:character, campaign: campaign, name: "Prism", pc: true)
                npc = create(:character, campaign: campaign, name: "Strahd", pc: false)

                Attendance.create!(session:, character: pc1, present: true)
                Attendance.create!(session:, character: pc2, present: true)
                Attendance.create!(session:, character: pc3, present: false)
                Attendance.create!(session:, character: npc, present: true)

                Sessions::Finalize.new(session).call!

                expect(pc1.reload.xp).to eq(5)
                expect(pc2.reload.xp).to eq(5)
                expect(pc3.reload.xp).to eq(0)
                expect(npc.reload.xp).to eq(0)
                
                att1 = Attendance.find_by!(session:, character: pc1)
                att2 = Attendance.find_by!(session:, character: pc2)

                expect(att1.xp_earned).to eq(5)
                expect(att2.xp_earned).to eq(5)

            end

        
            it "handles rounding by distributing remainder randomly" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "split", total_xp: 5)

                pc1 = create(:character, campaign: campaign, name: "Finch", pc: true, xp: 0)
                pc2 = create(:character, campaign: campaign, name: "Raphael", pc: true, xp: 0)

                Attendance.create!(session:, character: pc1, present: true)
                Attendance.create!(session:, character: pc2, present: true)

                Sessions::Finalize.new(session).call!

                pc1.reload
                pc2.reload

                expect(pc1.xp + pc2.xp).to eq(5)

                xp_values = [pc1.xp, pc2.xp].sort
                expect(xp_values).to eq([2, 3])
            end

            it "distributes remainder correctly with 3 PCs" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "split", total_xp: 10)

                pc1 = create(:character, campaign: campaign, name: "Finch", pc: true, xp: 0)
                pc2 = create(:character, campaign: campaign, name: "Raphael", pc: true, xp: 0)
                pc3 = create(:character, campaign: campaign, name: "Prism", pc: true, xp: 0)

                Attendance.create!(session:, character: pc1, present: true)
                Attendance.create!(session:, character: pc2, present: true)
                Attendance.create!(session:, character: pc3, present: true)

                Sessions::Finalize.new(session).call!

        
                pc1.reload
                pc2.reload
                pc3.reload

                expect(pc1.xp + pc2.xp + pc3.xp).to eq(10)

                xp_values = [pc1.xp, pc2.xp, pc3.xp].sort
                expect(xp_values).to eq([3, 3, 4])
            end

            it "does nothing if no pcs are present" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "split", total_xp: 10)
                npc = create(:character, campaign: campaign, name: "Strahd", pc: false)
                Attendance.create!(session:, character: npc, present: true)

                Sessions::Finalize.new(session).call!

                expect(npc.reload.xp).to eq(0)
            end

            it "raises error if total_xp is missing" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "split", total_xp: nil)

                expect { Sessions::Finalize.new(session).call!}
                    .to raise_error(Sessions::Finalize::Error, /Missing total_xp/)
            end
        end

        context "manual mode" do
            it "awards xp_earned for each present PC" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "manual")

                pc1 = create(:character, campaign: campaign, name: "Finch", pc: true)
                pc2 = create(:character, campaign: campaign, name: "Raphael", pc: true)
                npc = create(:character, campaign: campaign, name: "Strahd", pc: false)

                Attendance.create!(session:, character: pc1, present: true, xp_earned: 10)
                Attendance.create!(session:, character: pc2, present: true, xp_earned: 10)
                Attendance.create!(session:, character: npc, present: true, xp_earned: 10)

                Sessions::Finalize.new(session).call!

                expect(pc1.reload.xp).to eq(10)
                expect(pc2.reload.xp).to eq(10)
                expect(npc.reload.xp).to eq(0)
            end

            it "raises error if xp_earned is missing" do
                campaign = create(:campaign)
                session = create(:session, campaign:, status: "planned", scheduled_at: Time.current, xp_mode: "manual")

                pc = create(:character, campaign: campaign, name: "Finch", pc: true)
                Attendance.create!(session:, character: pc, present: true)

                expect { Sessions::Finalize.new(session).call!
             }.to raise_error(Sessions::Finalize::Error, /Missing xp_earned/)
            end

            it "raises error if session is already played" do
                campaign = create(:campaign)
                session = create(:session, campaign:, status: "played", scheduled_at: Time.current, xp_mode: "manual")
        
                expect { Sessions::Finalize.new(session).call!
             }.to raise_error(Sessions::Finalize::Error, /Session already played/)
            end

            it "does not mark session played if awarding fails" do
                campaign = create(:campaign)
                session = create(:session, campaign:, scheduled_at: Time.current, status: "planned", xp_mode: "manual")
              
                pc = create(:character, campaign:, pc: true, xp: 0)
                Attendance.create!(session:, character: pc, present: true)
              
                expect { Sessions::Finalize.new(session).call! }
                  .to raise_error(Sessions::Finalize::Error, /Missing xp_earned/)
              
                expect(session.reload.status).to eq("planned")
                expect(pc.reload.xp).to eq(0)
            end              
        end
    end
end

                
                