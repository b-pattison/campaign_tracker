require "rails_helper"

RSpec.describe "Campaigns", type: :request do
  describe "GET /campaigns" do
    it "renders index" do
      create(:campaign, name: "Curse of Strahd")
      get campaigns_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Campaigns")
      expect(response.body).to include("Curse of Strahd")
    end
  end

  describe "POST /campaigns" do
    it "creates a campaign and redirects to dashboard" do
      post campaigns_path, params: { campaign: { name: "Mirrorbound" } }
      expect(response).to redirect_to(dashboard_campaign_path(Campaign.last))
      follow_redirect!
      expect(response.body).to include("Mirrorbound")
      expect(response.body).to include("Dashboard")
    end

    it "renders errors for invalid campaign" do
      post campaigns_path, params: { campaign: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /campaigns/:id/dashboard" do
    it "shows next planned, last played, and active PCs with XP" do
      campaign = create(:campaign)

      create(:session, campaign:, title: "Session 10", scheduled_at: 2.days.from_now, played_at: nil)

      create(:session, campaign:, title: "Session 9", played_at: 1.day.ago)
      create(:session, campaign:, title: "Session 8", played_at: 2.days.ago)
      create(:session, campaign:, title: "Session 7", played_at: 3.days.ago)
      create(:session, campaign:, title: "Session 6", played_at: 4.days.ago)

      pc1 = create(:character, campaign:, pc: true, name: "Finch")
      pc2 = create(:character, campaign:, pc: true, name: "Prism")
      npc = create(:character, campaign:, pc: false, name: "Vulture")

      played = campaign.sessions.played.first
      create(:attendance, session: played, character: pc1, xp_earned: 50, present: true)
      create(:attendance, session: played, character: pc2, xp_earned: 25, present: true)
      create(:attendance, session: played, character: npc, xp_earned: 999, present: true)

      get dashboard_campaign_path(campaign)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Next Planned Session")
      expect(response.body).to include("Session 10")
      expect(response.body).to include("Last 3 Played Sessions")
      expect(response.body).to include("Session 9")
      expect(response.body).to include("Session 8")
      expect(response.body).to include("Session 7")
      expect(response.body).not_to include("Session 6")


      expect(response.body).to include("Finch")
      expect(response.body).to include("Prism")
      expect(response.body).not_to include("Vulture (NPC?)")
    end
  end
end

