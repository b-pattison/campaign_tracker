module Sessions
    class Finalize
        class Error < StandardError; end

        def initialize(session)
            @session = session
        end

        def call!
            @session.with_lock do
                raise Error, "Session already played" if @session.played?
                award_xp
                @session.update!(status: "played", played_at: Time.current)
            end
        @session
        end

        private

        def award_xp
            case @session.xp_mode
            when "manual"
                award_manual_xp
            when "split"
                award_split_xp
            else
                raise Error, "Unknown xp_mode: #{@session.xp_mode}"
            end
        end

        def award_manual_xp
            eligible_attendances.each do |attendance|
                xp = attendance.xp_earned
                raise Error, "Missing xp_earned for attendance #{attendance.id}" if xp.nil? || xp.zero?
                
                if attendance.character.pc?
                    attendance.character.increment!(:xp, xp)
                end
            end
        end

        def award_split_xp
            total = @session.total_xp
            raise Error, "Missing total_xp" if total.nil?

            pcs_present = eligible_attendances.select {
                |attendance| attendance.character.pc?
            }
            return if pcs_present.empty?

            base, remainder = total.divmod(pcs_present.size)

            # Shuffle to ensure fair distribution of remainder across sessions
            pcs_present.shuffle.each_with_index do |attendance, index|
                bonus = index < remainder ? 1 : 0
                xp = base + bonus
                attendance.character.update!(xp: attendance.character.xp + xp)
                attendance.update!(xp_earned: xp)
            end
        end

        def eligible_attendances
            @session.attendances.includes(:character).where(present: true)
        end
    end
end

            