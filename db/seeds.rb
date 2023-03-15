50.times do
  Entry.create({
    name: Faker::Name.name,
    description: Faker::Lorem.paragraph,
    date: Faker::Date.between(from: 30.days.ago, to: Date.today),
    value: Faker::Number.between(from: -1000.0, to: 1000.0),
  })
end
