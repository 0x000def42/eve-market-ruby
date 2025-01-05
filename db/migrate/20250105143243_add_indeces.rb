class AddIndeces < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :markets_orders,
                         "volume_remain > 0",
                         name: "volume_remain_positive"

    change_table :markets_orders do |t|
      t.index :type_id
    end
  end
end
