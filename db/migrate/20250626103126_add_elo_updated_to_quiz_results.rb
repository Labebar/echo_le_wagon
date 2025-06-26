class AddEloUpdatedToQuizResults < ActiveRecord::Migration[7.1]
  def change
    add_column :quiz_results, :elo_updated, :boolean, default: false, null: false
  end
end
