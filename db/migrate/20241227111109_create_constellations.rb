class CreateConstellations < ActiveRecord::Migration[8.0]
  def change
    create_table :constellations do |t|
      t.timestamps
      t.integer :eve_id, index: true

      t.belongs_to :region

      t.string :name
    end
  end
end
