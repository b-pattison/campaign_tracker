# frozen_string_literal: true

# Concern that provides automatic level calculation based on XP
module Levelable
  extend ActiveSupport::Concern

  XP_THRESHOLDS = {
    1 => 0,
    2 => 300,
    3 => 900,
    4 => 2700,
    5 => 6500,
    6 => 14000,
    7 => 23000,
    8 => 34000,
    9 => 48000,
    10 => 64000,
    11 => 85000,
    12 => 100000,
    13 => 120000,
    14 => 140000,
    15 => 165000,
    16 => 195000,
    17 => 225000,
    18 => 265000,
    19 => 305000,
    20 => 355000
  }.freeze

  included do
    before_save :calculate_level_from_xp, if: :should_calculate_level?
    after_save :notify_level_up, if: :saved_change_to_level?
  end

  def calculated_level
    @calculated_level ||= calculate_level_from_xp_value(total_xp)
  end

  def xp_for_next_level
    current_level = [level, calculated_level].max
    return nil if current_level >= 20

    next_level = current_level + 1
    XP_THRESHOLDS[next_level] - total_xp
  end

  def xp_progress_percentage
    return 100.0 if level >= 20

    current_level_xp = XP_THRESHOLDS[level]
    next_level_xp = XP_THRESHOLDS[level + 1]
    xp_in_current_level = total_xp - current_level_xp
    xp_needed_for_level = next_level_xp - current_level_xp

    ((xp_in_current_level.to_f / xp_needed_for_level) * 100).round(1)
  end

  def can_level_up?
    return false if level >= 20

    calculated_level > level
  end

  def level_up_message
    return nil unless can_level_up?

    "Level up! #{name} can advance from level #{level} to level #{calculated_level}"
  end

  def total_xp
    @total_xp ||= begin
      base_xp = xp || 0
      attendance_xp = attendances.sum(:xp_earned)
      base_xp + attendance_xp
    end
  end

  def clear_xp_cache!
    @total_xp = nil
    @calculated_level = nil
  end

  private

  def calculate_level_from_xp_value(xp_value)
    XP_THRESHOLDS.reverse_each do |level, threshold|
      return level if xp_value >= threshold
    end
    1
  end

  def should_calculate_level?
    return false if level_changed? && !xp_changed? && !new_record?
    
    xp_changed? || (new_record? && !level_changed?) || (attendances.any? && attendances.any?(&:changed?))
  end

  def calculate_level_from_xp
    new_level = calculate_level_from_xp_value(total_xp)
    self.level = [new_level, 20].min # Cap at level 20
  end

  def notify_level_up
    return unless saved_change_to_level?

    old_level, new_level = saved_change_to_level
    return if old_level.nil? || new_level.nil?
    return unless new_level > old_level

    Rails.logger.info("#{name} leveled up from #{old_level} to #{new_level}!")
  end
end
