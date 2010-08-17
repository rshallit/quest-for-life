GENDERS = ['Male', 'Female', nil]
AGE_GROUPS = AgeGroup.all.map(&:id)

n = 300

puts "Creating #{n} sample surveys..."
n.times do |i|
  survey = Survey.new(
    :gender => GENDERS.rand,
    :age_group_id => AGE_GROUPS.rand
  )

  Survey.parameter_columns.each do |col|
    random_valid_answer = Survey.send("#{col}_options").rand
    survey.send("#{col}_rational=", random_valid_answer)
  end

  survey.save!

  puts "created #{i} / #{n} surveys" if i % 25 == 0
end

puts "Done creating seed data"
