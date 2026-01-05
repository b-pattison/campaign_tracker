require 'rails_helper'

RSpec.describe Session, type: :model do
  it 'belongs to a campaign' do
    campaign = create(:campaign)
    session = create(:session, campaign: campaign)
    expect(session.campaign).to eq(campaign)
  end

  it 'has many attendances' do
    session = create(:session)
    character1 = create(:character, campaign: session.campaign)
    character2 = create(:character, campaign: session.campaign)
    attendance1 = create(:attendance, session: session, character: character1)
    attendance2 = create(:attendance, session: session, character: character2)
    
    expect(session.attendances).to contain_exactly(attendance1, attendance2)
  end
end
