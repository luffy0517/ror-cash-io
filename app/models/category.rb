# Category entity model definition
class Category < ApplicationRecord
  include PgSearch::Model
  belongs_to :user
  has_many :entries, dependent: :destroy
  mount_uploader :image, CategoryImageUploader
  validates :name, presence: true, uniqueness: true
  pg_search_scope :search_by_term, against: :name, using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
end
