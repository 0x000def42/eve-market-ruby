class System < ApplicationRecord
  belongs_to :constellation

  has_many :stations
  has_many :structures
end
