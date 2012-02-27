# Copyright (c) 2009 Steven Hammond, Cris Necochea, Joe Lind, Jeremy Weiskotten
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

class Survey < ActiveRecord::Base

  class << self
    def parameter_columns
      [:r_star, :fp, :ne, :fl, :fi, :fc, :l]
    end
    
    def title_for_parameter(p)
      {
        :n => 'Number of Civilizations',
        :r_star => 'Rate of Stellar Formation',
        :fp => "Fraction of Stars that Develop Planets",
        :ne => 'Number of Earthlike Planets',
        :fl => 'Frequency of Life Developing',
        :fi => 'Frequency of Intelligence Evolving',
        :fc => 'Frequency of Intelligent Civilization Communicating',
        :l => "Life Expectancy of an Advanced Society"
      }[p.to_sym]
    end
    
    def question_for_parameter(p)
      {
        :n => 'How many civilizations that might communicate with us are there in our galaxy?',
        :r_star => 'How many stars form in our galaxy each year?',
        :fp => "How many suitable stars actually form a solar system with planets in it?",
        :ne => 'What\'s the average number of bodies in a solar system capable of supporting liquid water?',
        :fl => 'How hard is it for life to start on a suitable planet?',
        :fi => 'If life starts on a planet, how likely is intelligence to develop?',
        :fc => 'Will an advanced civilization discover radio and choose to use it to communicate?',
        :l => "How many years can an advanced society survive?"
      }[p.to_sym]
    end

    def next_parameter(requested_parameter)
      return parameter_columns.first if requested_parameter.nil?
      requested_parameter = requested_parameter.to_sym
      raise "Invalid parameter: #{requested_parameter}" unless parameter_columns.include?(requested_parameter)
      index = parameter_columns.index(requested_parameter)
      parameter_columns[index+1]
    end

    def options_for(parameter)
      send("#{parameter}_options")
    end

    def r_star_options
      RationalOption.integers.quotient_gte(0).quotient_lte(100)
    end

    def fp_options
      RationalOption.quotient_gte((10**-6).to_f).quotient_lte(1)
    end

    def ne_options
      RationalOption.quotient_gte((10**-2).to_f).quotient_lte(10)
    end

    alias fl_options :fp_options
    alias fi_options :fp_options
    alias fc_options :fp_options

    def l_options
      RationalOption.quotient_gte(1).quotient_lte(10**6).reject{|o| Math.log10(o.quotient) % 1 != 0}
    end

    def report(parameter, dimension, selected_value)
      parameter_column = if :n == parameter.to_sym
        parameter.to_sym
      else
        "#{parameter}_rational_id".to_sym
      end
      count_options = {:group => parameter_column}
      dimension_column = survey_dimension_column(dimension)
      if dimension_column
        count_options[:conditions] = selected_value.blank? ? "#{dimension_column} is null" : "#{dimension_column} = '#{selected_value}'"
      end
          
      results = self.count(count_options)
      if :n == parameter.to_sym
        # group the results by order of magnitude
        grouped_data = results.group_by {|k, v| order_of_magnitude_label(k)}
        # sum the counts in each group
        data = grouped_data.map {|k, v| [k, v.inject(0) {|sum, pair| sum + pair[1]}]}.
          sort_by {|k, v| k.to_f}
      else
        data = results.map {|k, v| [RationalOption.find(k), v]}.
          sort_by {|k, v| k.quotient}.
          map {|k, v| [k.quotient_label, v]}
      end
      return {:caption => caption(dimension, selected_value), :data => data}
    end

    def order_of_magnitude_label(n)
      if n == 0
        "0"
      else
        log = Math.log10(n).floor
        "#{10 ** log}-#{(10 ** (log + 1)) - 1}"
      end
    end

    def caption(dimension, selected_value)
      case dimension.to_sym
      when :age
        "Estimates by age group #{selected_value.present? ? AgeGroup.find(selected_value).description : 'unknown'}"
      when :gender
        "Estimates by #{selected_value.present? ? selected_value.downcase.pluralize : 'people of unknown gender'}"
      when :all
        'All Estimates'
      end
    end

    def survey_dimension_column(dimension)
      case dimension.to_sym
      when :age
        :age_group_id
      when :gender
        :gender
      else
        nil
      end
    end
  end
  
  belongs_to :survey_group
  belongs_to :age_group
    
  validates_numericality_of parameter_columns, :n, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_presence_of :slug
  validates_uniqueness_of :slug, :on => :create

  before_validation_on_create :set_slug
  before_validation :strip_at_from_twitter_username
  before_save :store_group_demigraphics
  before_save :calculate_quotients
  before_save :cleanup_empty_strings
  
  attr_accessible *(parameter_columns.map{|p| "#{p}_rational_id".to_sym })
  attr_accessible :city, :state, :country, :age_group_id, :gender, :activity_id, :lit_type_id, :twitter_username

  belongs_to :lit_type
  belongs_to :activity

  belongs_to :r_star_rational, :class_name => 'RationalOption'
  belongs_to :fp_rational, :class_name => 'RationalOption'
  belongs_to :ne_rational, :class_name => 'RationalOption'
  belongs_to :fl_rational, :class_name => 'RationalOption'
  belongs_to :fi_rational, :class_name => 'RationalOption'
  belongs_to :fc_rational, :class_name => 'RationalOption'
  belongs_to :l_rational, :class_name => 'RationalOption'
  
  def to_param
    slug
  end
  
  def completed?
    self.n.present?
  end
  
  def address
    "#{self.city}, #{self.state+' '}#{self.country}"
  end
  
  private
  
  def store_group_demigraphics
    if survey_group
      self.country = survey_group.country
      self.state = survey_group.state
      self.city = survey_group.city
      self.age_group_id = survey_group.age_group_id
    end
  end
  
  def calculate_quotients
    Survey.parameter_columns.each do |column|
      send("#{column}=", send("#{column}_rational").try(:quotient))
    end
    values = Survey.parameter_columns.map { |p| self.send(p) }
    if values.all?
      self.n = values.inject(1.0) { |product, v| product * v }.round
    else
      self.n = nil
    end
    true
  end
  
  def set_slug
    self.slug = ActiveSupport::SecureRandom.hex(4) # 8 hex digits
  end
  
  def strip_at_from_twitter_username
    self.twitter_username.gsub!('@', '') if self.twitter_username.present?
  end
  
  def cleanup_empty_strings
    self.gender = nil if self.gender == ''
  end
end
