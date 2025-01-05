class CreateStructures < ActiveRecord::Migration[8.0]
  def change
    create_table :structures do |t|
      t.timestamps

      t.belongs_to :system

      t.string :name
      t.integer :owner_id
      t.integer :type_id
      t.bigint :eve_id, index: true
    end
  end
end
