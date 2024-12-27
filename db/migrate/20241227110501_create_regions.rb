class CreateRegions < ActiveRecord::Migration[8.0]
  def change
    create_table :regions do |t|
      t.timestamps

      t.string :name
      t.integer :eve_id, index: true
    end
  end
end
