class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.order(created_at: :desc)
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new(campaign_params)

    if @campaign.save
      redirect_to dashboard_campaign_path(@campaign), notice: "Campaign created."
    else
      @campaigns = Campaign.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end
  def dashboard
    @campaign = Campaign.find(params[:id])

    @next_planned_session =
      @campaign.sessions
      .planned
      .order(scheduled_at: :asc)
      .first

    @last_played_sessions =
      @campaign.sessions
      .played
      .order(played_at: :desc)
      .limit(3)

    @active_pcs_with_xp =
      @campaign.characters
      .where(pc: true)
      .left_joins(:attendances)
      .group("characters.id")
      .select(
        "characters.*",
        "COALESCE(SUM(attendances.xp_earned), 0) AS total_xp"
      )
      .order(Arel.sql("total_xp DESC, characters.name ASC"))
  end

  def show
    @campaign = Campaign.find(params[:id])

    @recent_sessions = @campaign.sessions.order(scheduled_at: :desc).limit(5)

    @top_characters = @campaign.characters
    .where(pc: true)
    .order(xp: :desc)
    .limit(6)

    @attendance_last_10 = Attendance
    .joins(:session)
    .order(xp: :desc)
    .limit(6)
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end
end

