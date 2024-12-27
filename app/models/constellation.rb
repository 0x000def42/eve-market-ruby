class Constellation < ApplicationRecord
  belongs_to :region
  has_many :systems
end
