class Website < ApplicationRecord
  has_many :pages, dependent: :destroy
end