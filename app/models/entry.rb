class Entry < ApplicationRecord
  include OrderableByTimestamp
  include PgSearch::Model

  validates :name, presence: true
  validates :date, presence: true
  validates :value, presence: true

  pg_search_scope :search_by_term,
    against: :name,
    using: {
      tsearch: {
        any_word: true,
        prefix: true,
      },
    }
end
