class User < ApplicationRecord
  has_secure_password
  has_many :entries, dependent: :destroy
  mount_uploader :avatar, AvatarUploader
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true
  validates :password, length: { minimum: 6, maximum: 20 }, on: :create
end
