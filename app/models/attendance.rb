class Attendance < ApplicationRecord
  belongs_to :session
  belongs_to :character

  validates :xp_earned, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  after_save :update_character_level
  after_destroy :update_character_level

  private

  def update_character_level
    return unless character.respond_to?(:clear_xp_cache!)

    character.clear_xp_cache!
    
    character.xp_will_change! if character.respond_to?(:xp_will_change!)
    character.save!
  end
end
