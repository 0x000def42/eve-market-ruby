class Add < ActiveRecord::Migration[8.0]
  def change
    change_table :regions do |t|
      t.integer :market_pages
    end
  end
end
