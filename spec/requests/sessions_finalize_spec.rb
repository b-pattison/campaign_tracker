require "rails_helper"

RSpec.describe "Sessions Finalize", type: :request do
    describe "POST /sessions/:id/finalize" do

        context "when finalize succeeds" do
            it "finalizes the sessions and returns 200 with payload" do
                campaign = create(:campaign)
                session = create(:session, campaign: campaign, status: "planned", xp_mode: "split", total_xp: 10)
                character1 = create(:character, campaign: campaign, xp: 0)
                character2 = create(:character, campaign: campaign, xp: 0)
                Attendance.create!(session: session, character: character1, present: true, xp_earned: 0)
                Attendance.create!(session: session, character: character2, present: true, xp_earned: 0)

                post "/sessions/#{session.id}/finalize", params: { mode: "split", total_xp: 10 }

                expect(response).to have_http_status(:ok)
                expect(session.reload.status).to eq("played")
                expect(character1.reload.xp).to eq(5)
                expect(character2.reload.xp).to eq(5)
            end
        end

        context "when session is not found" do
            it "returns 404" do
                post "/sessions/999/finalize", params: { mode: "split", total_xp: 10 }

                expect(response).to have_http_status(:not_found)
                expect(JSON.parse(response.body)).to eq({ "error" => "Session not found" })
            end
        end

        context "when finalize fails validation" do
            it "returns 422 with validation errors" do
                campaign = create(:campaign)
                session = create(:session, campaign: campaign, status: "planned", xp_mode: "split", total_xp: nil)

                post "/sessions/#{session.id}/finalize", params: { mode: "split", total_xp: nil }

                expect(response).to have_http_status(:unprocessable_content)
                expect(JSON.parse(response.body)["error"]).to be_present
            end
        end
    end
end