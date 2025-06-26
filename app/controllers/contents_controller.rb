class ContentsController < ApplicationController
  before_action :authenticate_user!
  def generate_questions
    @content = Content.find(params[:id])
    @saved_questions = @content.generate_questions

  # if questions_data.blank? || !questions_data.is_a?(Array)
  #   render json: { error: "Aucune question générée." }, status: :unprocessable_entity
  #   return
  # end
    render :show
  end

  def index
    @content = Content.new
    @contents = if params[:query].present?
                  Content.search_by_name_and_tags(params[:query])
                else
                  current_user.contents.by_recent
                end
    build_personal_playlists
  end

  def show
    @content = Content.find(params[:id])
    @questions = @content.questions.shuffle
  end

  def edit
    @content = Content.find(params[:id])
  end

  def update
    @content = Content.find(params[:id])
    @content.update(content_params)
    render :show
  end

  def new
    @content = Content.new
  end

  def create
    @content = Content.new(content_params)
    @content.user = current_user

    if @content.save

      @content.enrich!
      ContentJob.perform_later(@content)
      flash[:success] = "🎉 Content enriched!"
      redirect_to content_path(@content)

    else
      flash[:alert] = "🚫 Error occurred!"
      redirect_to contents_path
    end
  end

  def notes
    Rails.logger.info "=== ACTION NOTES APPELÉE ==="
    @content = Content.find(params[:id])
    @notes = @content.notes
    @note = @content.notes.build

    Rails.logger.info "Content ID: #{@content.id}"
    Rails.logger.info "Notes count: #{@notes.count}"

    respond_to do |format|
      format.turbo_stream do
        Rails.logger.info "=== TURBO STREAM RESPONSE ==="
      end
      format.html { redirect_to @content } # Fallback
    end
  end

  def destroy
    @content = Content.find(params[:id])
    @content.destroy
    flash[:success] = "Content deleted!"
    redirect_to contents_path
  end

  def results
    @content = Content.find(params[:id])
    @questions = @content.questions
    validated_count = @questions.where(validated: true).count
    total_count = @questions.count

    quiz_result = QuizResult.find_or_initialize_by(user: current_user, content: @content)
    quiz_result.correct_answers = validated_count
    quiz_result.total_questions = total_count

    if validated_count == total_count && quiz_result.completed_at.nil?
      quiz_result.completed_at = Time.current
    end
    unless quiz_result.elo_updated
      current_user.update_elo_for_quiz(validated_count, quiz_result)
      quiz_result.elo_updated = true
    end
    quiz_result.save!
  end

  private

  def content_params
    params.require(:content).permit(:url, :name)
  end

  def build_personal_playlists
    @favorite_tags = Tag.joins(:content_tags)
                        .where(content_tags: { favorite: true })
                        .distinct

    @personal_playlists = @favorite_tags.each_with_object({}) do |tag, hash|
      contents = Content.joins(:content_tags)
                        .where(content_tags: { favorite: true, tag_id: tag.id })
                        .where(user: current_user)
      hash[tag] = contents if contents.any?
    end
  end
end
