class CreateEloHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :elo_histories do |t|
      t.integer :value
      t.references :user, null: false, foreign_key: true
      t.references :quiz_result, null: false, foreign_key: true

      t.timestamps
    end
  end
end
