class MarketsOrder < ApplicationRecord
  belongs_to :system
  belongs_to :type, class_name: "ItemType", foreign_key: :type_id

  default_scope -> { joins(:system).where("systems.security_status >= ?", 0.5) }
end
