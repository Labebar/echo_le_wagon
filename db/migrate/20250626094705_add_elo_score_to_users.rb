class AddEloScoreToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :elo_score, :integer, default: 1500, null: false
  end
end
