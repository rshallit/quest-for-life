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

module SurveysHelper
  def info_link(name, url)
    link_to name, url, :target => '_blank'
  end
  
  def main_point(text)
    "<a href=\"#\">#{text}&hellip;</a>"
  end

  def parameter_input form, parameter
    rational_attribute = parameter.to_s + '_rational_id'
    collection = Survey.options_for(parameter)
    label_method = "#{parameter}_label".to_sym

    form.input rational_attribute, :collection => collection,
      :include_blank => false,
      :as => :select,
      :value_method => :id,
      :label_method => label_method
  end
   
  def chart_options(parameter, dimension, survey, options={})
    options[:parameter] = parameter
    options[:demographic] = dimension
     
    options[:select_options] = case dimension
    when :age
      (AgeGroup.all + [AgeGroup.new(:id => nil, :description => 'Unknown')]).map {|ag| [ag.description, ag.id]}
    when :gender
      [['Male']*2, ['Female']*2, ['Unknown', nil]]
    end
    if dimension != :all
      survey_dimension_column = Survey.survey_dimension_column(dimension)
      options[:selected] = survey.try(survey_dimension_column)
    end
    options[:data] = Survey.report(parameter, dimension, options[:selected])
     
    return options
  end
   
   def chart(parameter, dimension, options={})
     render :partial => 'chart_set', :locals => chart_options(parameter, dimension, options)
   end
  
  def data_format(num)
    if num > 9_999_999
      return '%0.2e' % num.to_f
    elsif num > 100
      return num.round.commify
    else
      return "%0.2f" % num.to_f
    end
  end
end
