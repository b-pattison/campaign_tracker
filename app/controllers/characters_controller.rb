class CharactersController < ApplicationController
    before_action :set_character, only: %i[show update destroy]

    def index
        @characters = Character.order(:name)
        render json: @characters
    end

    def show
        render json: @character
    end

    def create
        character = Character.new(character_params)

        if character.save
            render json: character, status: :created
        else
            render json: { errors: character.errors.full_messages }, status: :unprocessable_content
        end
    end

    def update
        if @character.update(character_params)
            render json: @character
        else
            render json: { errors: @character.errors.full_messages }, status: :unprocessable_content
        end
    end

    def destroy
        @character.destroy!
        head :no_content
    end

    private

    def set_character
        @character = Character.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render json: { error: "Character not found" }, status: :not_found
    end

    def character_params
        params.require(:character).permit(:name, :class_name, :level, :ancestry, :notes, :pc, :campaign_id)
    end
end