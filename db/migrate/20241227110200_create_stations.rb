class CreateStations < ActiveRecord::Migration[8.0]
  def change
    create_table :stations do |t|
      t.timestamps

      t.belongs_to :system

      t.integer :eve_id, index: true
      t.string :name
    end
  end
end
