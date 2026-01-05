require 'rails_helper'

RSpec.describe Campaign, type: :model do
  it { should validate_presence_of(:name) }

  it "is valid with valid attributes" do
    expect(build(:campaign)).to be_valid
  end
end
