class Session < ApplicationRecord
  belongs_to :campaign
  has_many :attendances, dependent: :destroy
  enum :status, { planned: "planned", played: "played", canceled: "canceled" }

  scope :played, -> { where.not(played_at: nil)}
  scope :planned, -> { where(played_at: nil).where.not(scheduled_at: nil)}
end
