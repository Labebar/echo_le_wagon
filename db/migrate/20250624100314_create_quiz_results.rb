class CreateQuizResults < ActiveRecord::Migration[7.1]
  def change
    create_table :quiz_results do |t|
      t.references :user, null: false, foreign_key: true
      t.references :content, null: false, foreign_key: true
      t.integer :correct_answers
      t.integer :total_questions

      t.timestamps
    end
  end
end
