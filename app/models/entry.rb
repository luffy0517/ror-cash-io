class Entry < ApplicationRecord
  include OrderableByTimestamp

  validates :name, presence: true
  validates :date, presence: true
  validates :value, presence: true
end
