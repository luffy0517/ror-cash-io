# User entity model definition
class User < ApplicationRecord
  include PgSearch::Model
  has_secure_password
  has_many :entries, dependent: :destroy
  mount_uploader :avatar, UserAvatarUploader
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true, on: :create
  validates :password, length: { minimum: 6, maximum: 20 }, on: :create
  pg_search_scope :search_by_term, against: %i[first_name last_name email username], using: {
    tsearch: {
      any_word: true,
      prefix: true
    }
  }
end
