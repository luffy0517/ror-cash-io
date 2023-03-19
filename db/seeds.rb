User.create({
              first_name: 'root',
              last_name: 'admin',
              username: 'admin',
              email: 'root@admin.com',
              password: ENV['ROOT_ADMIN_PASSWORD']
            })

entry_categories = [
  {
    name: 'Other',
    user_id: 1
  },
  {
    name: 'Groceries',
    user_id: 1
  },
  {
    name: 'Transport',
    user_id: 1
  },
  {
    name: 'Health',
    user_id: 1
  },
  {
    name: 'Leisure',
    user_id: 1
  },
  {
    name: 'Habitation',
    user_id: 1
  },
  {
    name: 'Communication',
    user_id: 1
  }
]

entry_categories.each { |category| Category.create(category) }

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
