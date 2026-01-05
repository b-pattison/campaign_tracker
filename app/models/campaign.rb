class Campaign < ApplicationRecord
  validates :name, presence: true

  has_many :sessions, dependent: :destroy
  has_many :characters, dependent: :destroy
end
