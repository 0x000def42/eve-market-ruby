class CreateSystems < ActiveRecord::Migration[8.0]
  def change
    create_table :systems do |t|
      t.timestamps

      t.integer :eve_id, index: true

      t.belongs_to :constellation

      t.string :name
      t.string :security_class
      t.decimal :security_status
    end
  end
end
