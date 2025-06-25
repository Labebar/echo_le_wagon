class AddCompletedAtToQuizResults < ActiveRecord::Migration[7.1]
  def change
    add_column :quiz_results, :completed_at, :datetime
  end
end
