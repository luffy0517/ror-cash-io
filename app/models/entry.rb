# Entry entity model definition
class Entry < ApplicationRecord
  include PgSearch::Model
  belongs_to :user
  belongs_to :category
  validates :name, presence: true
  validates :date, presence: true
  validates :value, presence: true
  pg_search_scope :search_by_term, against: %i[name description], using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
  pg_search_scope :search_by_category_id, against: :category_id, using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
end
