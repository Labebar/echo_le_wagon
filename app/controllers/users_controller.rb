class UsersController < ApplicationController
  before_action :authenticate_user!
  def profile
    @user = current_user
    @content_number = @user.contents.count
    quiz_per_day
    quiz_rate
    best_category
    color
    elo_data
    elo_progression
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

  def elo_data
    @elo_data = current_user.elo_histories.order(created_at: :asc).map do |h|
      [h.created_at.strftime('%Y-%m-%d'), h.value]
    end
  end

  def elo_progression
    seven_days_ago = 6.days.ago.beginning_of_day

    # Cherche la dernière valeur connue *avant ou à* 7 jours
    past_elo = current_user.elo_histories
                           .where('created_at <= ?', seven_days_ago)
                           .order(created_at: :desc)
                           .limit(1)
                           .pluck(:value)
                           .first

    # Si aucune entrée trouvée, utiliser 1500 comme valeur de départ
    past_elo ||= 1500

    @elo_change = current_user.elo_score - past_elo
  end
end
