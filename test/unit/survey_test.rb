require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
  should_validate_numericality_of :r_star, :fp, :ne, :fl, :fi, :fc, :l, :n
  should_belong_to :survey_group
  should_belong_to :lit_type
  should_belong_to :activity
  should_not_allow_mass_assignment_of :id, :created_at, :updated_at
  
  test "n is nil if any parameter is nil" do
    # initialize all to non-nil
    params = Survey.parameter_columns.inject({}) { |hash, p| hash["#{p}_rational"] = Factory(:rational_option); hash } 
    survey = Factory.create(:survey, params)
    assert_not_nil survey.n, 'should have a non-nil N'
    
    Survey.parameter_columns.each do |p|
      original_value = survey.send "#{p}_rational"
      survey.send "#{p}_rational=", nil
      survey.save!
      
      assert_nil survey.n
      
      # set the parameter back 
      survey.send "#{p}_rational=", original_value
    end
  end
  
  test "n is calculated correctly" do
    rationals =
      {
        :r_star_rational_id => Factory.create(:rational_option).id,
        :fp_rational_id => Factory.create(:rational_option).id,
        :ne_rational_id => Factory.create(:rational_option).id,
        :fl_rational_id => Factory.create(:rational_option).id,
        :fi_rational_id => Factory.create(:rational_option).id,
        :fc_rational_id => Factory.create(:rational_option).id,
        :l_rational_id => Factory.create(:rational_option).id
      }
    survey = Factory.create(:survey, rationals)
    product = rationals.values.inject(1.0) { |product, v| product * RationalOption.find(v).quotient }.round
    assert_equal product.round, survey.n
  end
  
  test "slug gets set on create" do
    survey = Factory.build(:survey, :slug => nil)
    assert_nil survey.slug
    survey.save
    assert_not_nil survey.slug
  end
  
  test "to_param returns slug" do
    survey = Factory.build(:survey, :slug => '12345678')
    assert_equal survey.slug, survey.to_param
  end
  
  test "gender should not save as an empty string" do
    survey = Factory.create(:survey, :gender => nil)
    assert_equal nil, survey.gender
    
    survey.gender = ''
    assert survey.save
    assert_equal nil, survey.gender

    survey.gender = "Male"
    assert survey.save
    assert_equal "Male", survey.gender
  end

  test "report" do
    rational_options = [1, 10].map {|n| Factory.create(:rational_option, :numerator => 1, :denominator => n)}
    age_groups = (1..2).map {|n| Factory.create(:age_group)}
    surveys = [['Male', age_groups[0].id, rational_options[0].id],
               ['Female', age_groups[1].id, rational_options[1].id],
               [nil, nil, rational_options[1].id]].map do |g, a, r|
      rational_option_hash = Hash[['r_star', 'fp', 'ne', 'fl', 'fi', 'fc', 'l'].
                                  map {|param| ["#{param}_rational_id".to_sym, r]}]
      Factory.create(:survey, {:gender => g, :age_group_id => a}.merge(rational_option_hash))
    end
    
    data = [[:n, :all, nil, {:caption => 'All Estimates',
        :data => [['0', 2], ['1-9', 1]]}],
      [:n, :gender, 'Male', {:caption => 'Estimates by males',
        :data => [['1-9', 1]]}],
      [:n, :gender, nil, {:caption => 'Estimates by people of unknown gender',
        :data => [['0', 1]]}],
      [:ne, :all, nil, {:caption => 'All Estimates',
        :data => [['1 in 10', 2], ['1', 1]]}],
      [:ne, :age, age_groups[0].id, {:caption => "Estimates by age group #{age_groups[0].description}",
        :data => [['1', 1]]}],
      [:ne, :age, nil, {:caption => 'Estimates by age group unknown',
        :data => [['1 in 10', 1]]}]]
    data.each do |param, dimension, value, report|
      assert_equal report, Survey.report(param, dimension, value)
    end
  end
end
