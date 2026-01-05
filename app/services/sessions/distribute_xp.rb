# frozen_string_literal: true

# Service object for distributing XP to characters based on session attendance
module Sessions
  class DistributeXp
    attr_reader :session, :xp_mode, :total_xp, :errors

    MODES = {
      equal: :equal_distribution,
      attendance_based: :attendance_based_distribution,
      level_scaled: :level_scaled_distribution
    }.freeze

    def initialize(session, xp_mode: :equal, total_xp: nil)
      @session = session
      @xp_mode = xp_mode.to_sym
      @total_xp = total_xp || session.total_xp || 0
      @errors = []
    end

    def call
      return failure("Session not found") unless session
      return failure("No XP to distribute") if total_xp.zero?
      return failure("Invalid XP mode") unless MODES.key?(@xp_mode)

      distribute_xp
      success
    rescue StandardError => e
      failure("Error distributing XP: #{e.message}")
    end

    def success?
      errors.empty?
    end

    private

    def distribute_xp
      method_name = MODES[@xp_mode]
      send(method_name)
    end

    def equal_distribution
      present_attendances = session.attendances.where(present: true).includes(:character)
      return if present_attendances.empty?

      xp_per_character = (total_xp.to_f / present_attendances.count).round

      present_attendances.find_each do |attendance|
        attendance.update!(xp_earned: xp_per_character)
        attendance.character.clear_xp_cache! if attendance.character.respond_to?(:clear_xp_cache!)
        attendance.character.save!
      end

      absent_attendances = session.attendances.where(present: false).includes(:character)
      absent_attendances.find_each do |attendance|
        attendance.update!(xp_earned: 0)
        attendance.character.clear_xp_cache! if attendance.character.respond_to?(:clear_xp_cache!)
        attendance.character.save!
      end
    end

    def attendance_based_distribution
      session.attendances.includes(:character).find_each do |attendance|
        xp_amount = attendance.present? ? total_xp : (total_xp / 2.0).round
        attendance.update!(xp_earned: xp_amount)
        attendance.character.clear_xp_cache! if attendance.character.respond_to?(:clear_xp_cache!)
        attendance.character.save!
      end
    end

    def level_scaled_distribution
      present_attendances = session.attendances.where(present: true).includes(:character).to_a
      return if present_attendances.empty?

      present_attendances.each { |a| a.character.reload }
      
      total_level = present_attendances.sum { |a| a.character.level }
      return if total_level.zero?

      present_attendances.each do |attendance|
        level_weight = attendance.character.level.to_f / total_level
        xp_amount = (total_xp * level_weight).round
        attendance.update!(xp_earned: xp_amount)
        attendance.character.clear_xp_cache! if attendance.character.respond_to?(:clear_xp_cache!)
        attendance.character.save!
      end
    end

    def success
      @errors = []
      self
    end

    def failure(message)
      @errors << message
      self
    end
  end
end
