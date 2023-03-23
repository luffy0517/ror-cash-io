1800.times do
  Entry.create({
                  category_id: Faker::Number.between(from: 1, to: 7),
                  user_id: 1,
                  name: Faker::Name.name,
                  description: Faker::Lorem.paragraph,
                  date: Faker::Date.between(from: 180.days.ago, to: Date.today),
                  value: Faker::Number.between(from: -1000, to: 1000)
                })
end
