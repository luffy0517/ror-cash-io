class Entry < ApplicationRecord
  validates :name, presence: true
  validates :date, presence: true
  validates :value, presence: true
end
