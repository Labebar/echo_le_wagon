class UsersController < ApplicationController
  before_action :authenticate_user!
  def profile
    @user = current_user
    @content_number = @user.contents.count
    quiz_per_day
    quiz_rate
    best_category
    color
  end

  private

  def quiz_per_day
    @quizzes_per_day = QuizResult.where(user_id: current_user.id)
                                 .where.not(completed_at: nil)
                                 .group_by_week(:completed_at, last: 4)
                                 .count
  end

  def quiz_rate
    results = @user.quiz_results
    total_correct = results.sum(:correct_answers)
    total_questions = results.sum(:total_questions)
    global_score = total_questions.positive? ? (total_correct.to_f / total_questions * 100).round(2) : 0
    @formatted_score = (global_score % 1).zero? ? global_score.to_i : global_score
  end

  def best_category
    personal_playlists = current_user.personal_playlists
    max_size = personal_playlists.values.map(&:size).max
    @top_tags = personal_playlists.select { |_, contents| contents.size == max_size }.keys
  end

  def color
    @score_color = if @formatted_score < 50
                     "#E5484D"
                   elsif @formatted_score < 80
                     "#E57F4D"
                   else
                     "#139986"
                   end
  end
end
