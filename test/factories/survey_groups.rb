Factory.define :survey_group do |survey_group|
  survey_group.user_id { Factory(:user) }
  survey_group.sequence(:group_name){|n| "group #{n}"}
  survey_group.age_group { Factory(:age_group) }
end