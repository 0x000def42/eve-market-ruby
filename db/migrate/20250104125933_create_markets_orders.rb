class CreateMarketsOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :markets_orders do |t|
      t.timestamps
      t.belongs_to :system

      t.integer :duration
      t.boolean :is_buy_order
      t.string :issued
      t.bigint :location_id
      t.integer :min_volume
      t.bigint :order_id
      t.decimal :price
      t.string :range
      t.integer :type_id
      t.integer :volume_remain
      t.integer :volume_total

      t.index :order_id, unique: true
    end
  end
end
