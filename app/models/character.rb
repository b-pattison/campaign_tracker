class Character < ApplicationRecord
  include Levelable

  belongs_to :campaign
  has_many :attendances, dependent: :destroy
  has_many :sessions, through: :attendances

  validates :name, presence: true
  validates :class_name, presence: true
  validates :level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 20 }

  scope :by_level, -> { order(level: :desc, name: :asc) }
  scope :for_class, ->(klass) { where("LOWER(class_name) = ?", klass.to_s.downcase) }
  scope :can_level_up, -> { where("level < 20") }
end
