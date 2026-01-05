puts "Begin seeding campaign data."

begin
campaign = Campaign.find_or_create_by!(name: "Curse of Strahd") do |c|
  c.description = "A gothic horror campaign set in Barovia."
end

puts "Campaign seeded: #{campaign.name}"

puts "Begin seeding character data."

characters = [
    {
        name: "Finch",
        pc: true,
        class_name: "Wizard",
        subclass_name: "Abjuration",
        level: 5,
        ancestry: "Elf",
        notes: "Abjuration specialist raised in a tower. Part of a super secret society of artifact hunters called the Seekers.",
        xp: 0
    },
    {
        name: "Prism",
        pc: true,
        class_name: "Cleric",
        subclass_name: "Light Domain",
        level: 5,
        ancestry: "Half-Elf",
        notes: "Light domain cleric with an eccentric, colorful fashion sense.",
        xp: 0
    },
    {
        name: "Raphael",
        pc: true,
        class_name: "Paladin",
        subclass_name: "Vengeance",
        level: 5,
        ancestry: "Dhampir",
        notes: "Vengeance paladin with a dark past.",
        xp: 0
    },
    {
        name: "Vulture",
        pc: false,
        class_name: "Fighter",
        subclass_name: "Eldritch Knight",
        level: 5,
        ancestry: "Human",
        notes: "Eldritch knight with bright red hair and cursed armor.",
    }
]

characters.each do |chara|
    character = campaign.characters.find_or_create_by!(name: chara[:name]) do |c|
      c.pc = chara[:pc]
      c.class_name = chara[:class_name]
      c.subclass_name = chara[:subclass_name]
      c.level = chara[:level]
      c.ancestry = chara[:ancestry]
      c.notes = chara[:notes]
    end
end

puts "Characters seeded:\n #{characters.map { |c| c[:name] }.join(", ")}."


puts "Begin seeding session data."

Session.find_or_create_by!(
    campaign: campaign,
    title: "Session 13 — Lathander's Blessing",
    ) do |s|
    s.scheduled_at = 18.days.from_now
    s.status = "planned"
    end

Session.find_or_create_by!(
    campaign: campaign,
    title: "Session 12 — Baba Lysaga's Hut",
    ) do |s|
    s.scheduled_at = 27.days.ago
    s.played_at = 25.days.ago
    s.status = "played"
    end

Session.find_or_create_by!(
    campaign: campaign,
    title: "Session 11 — Miracella's Lair and meeting Ezmerelda",
    ) do |s|
    s.scheduled_at = 55.days.ago
    s.played_at = 53.days.ago
    s.status = "played"
    end

sessions = campaign.sessions
puts "Sessions seeded:\n #{sessions.map(&:title).join(", ")}."

puts "Begin seeding attendance data."
played_session = campaign.sessions.played.first

if played_session
  pcs = campaign.characters.where(pc: true)

  pcs.each do |pc|
    Attendance.find_or_create_by!(
      session: played_session,
      character: pc
    ) do |a|
      a.present = true
      a.xp_earned = 50
    end
  end

  puts "Seeded attendance for played session."
else
  puts "No played sessions found, skipping attendance seeding."
end

puts "Campaign seed complete."

rescue StandardError => e
    puts "Error seeding data:\n #{e.message}."
    raise e
end