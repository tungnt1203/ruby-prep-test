# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[user host] }
  validates :password, length: { minimum: 6 }, allow_nil: true

  def host?
    role == "host"
  end

  def user?
    role == "user"
  end
end
