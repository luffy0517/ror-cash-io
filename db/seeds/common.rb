root_user = User.create({
                          first_name: 'root',
                          last_name: 'user',
                          username: 'user',
                          email: 'root@user.com',
                          password: ENV['ROOT_USER_PASSWORD']
                        })

entry_categories = %w[
  Other
  Groceries
  Transport
  Health
  Leisure
  Habitation
  Communication
]

entry_categories.each { |category| root_user.categories.create({ name: category }) }
