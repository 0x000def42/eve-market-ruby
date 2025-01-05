class CreateItemTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :item_types do |t|
      t.timestamps

      t.integer :eve_id, index: true
      t.string :name
      t.float :mass
    end
  end
end
