class SessionsController < ApplicationController
    before_action :set_session, only: %i[show update destroy finalize]

    def index
        sessions = Sessions.order(date: :desc)
        render json: sessions
    end

    def show
        render json: @session
    end

    def create
        session = Session.new(session_params)
        if session.save
            render json: session, status: :created
        else
            render json: { error: session.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
    end

    def update
        if @session.update(session_params)
            render json: @session
        else
            render json: { error: @session.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
    end

    def destroy
        @session.destroy
        head :no_content
    end

    def finalize
        @session.update!(xp_mode: params.fetch(:mode, "split"), total_xp: params[:total_xp])
        result = Sessions::Finalize.new(@session).call!

        render json: result, status: :ok
    rescue Sessions::Finalize::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_session 
        @session = Session.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render json: { error: "Session not found" }, status: :not_found
    end

    def session_params
        params.require(:session).permit(:scheduled_at, :recap, :location, :status)
    end
end