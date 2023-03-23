ActiveRecord::Base.transaction do
  ['common', Rails.env].each do |seed_file_name|
    seed_file = "#{Rails.root}/db/seeds/#{seed_file_name}.rb"
    if File.exist?(seed_file)
      puts "-- Seeding data from file: #{seed_file_name}"
      require seed_file
    end
  end
end
