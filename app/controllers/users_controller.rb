class UsersController < ApplicationController
  before_action :authenticate_user!
  def profile
    @user = current_user
    results = @user.quiz_results
    total_correct = results.sum(:correct_answers)
    total_questions = results.sum(:total_questions)
    global_score = total_questions.positive? ? (total_correct.to_f / total_questions * 100).round(2) : 0
    @formatted_score = (global_score % 1).zero? ? global_score.to_i : global_score
    @content_number = Content.all.count
  end
end
