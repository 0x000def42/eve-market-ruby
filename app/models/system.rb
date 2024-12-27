class System < ApplicationRecord
  belongs_to :constellation

  has_many :stations
end
