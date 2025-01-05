class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.timestamps

      t.string :token
      t.string :uid
      t.datetime :expires_on
      t.string :name
      t.string :character_id
    end
  end
end
