require 'rails_helper'

RSpec.describe Attendance, type: :model do
  it 'belongs to a session' do
    session = create(:session)
    character = create(:character, campaign: session.campaign)
    attendance = create(:attendance, session: session, character: character)
    expect(attendance.session).to eq(session)
  end

  it 'belongs to a character' do
    session = create(:session)
    character = create(:character, campaign: session.campaign)
    attendance = create(:attendance, session: session, character: character)
    expect(attendance.character).to eq(character)
  end
end
