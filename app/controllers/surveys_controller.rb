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

class SurveysController < ApplicationController
  before_filter :find_parameter, :only => :edit
  before_filter :only_show_if_completed, :only => :show
  before_filter :authorize, :only => [:edit, :update]
  
  make_resourceful do
    actions :new, :create, :show, :index, :edit, :update
    belongs_to :survey_group

    before :index, :show do
      @parameter = params[:p] || 'n'
    end

    before :edit do
      if @parameter == 'n'
        redirect_to :action => :show, :id => params[:id]
      end
    end
    
    before :update do
      logger.warn params[:activity_id]
    end
    
    after :create do
      # store survey id in the user's session, which authorizes them to edit/update
      session[:survey_id] = current_object.id
    end

    response_for :create do |format|
      format.html do
        redirect_to edit_survey_path(current_object)
      end
    end
    response_for :update do |format|
      format.html do
        if params[:demographics].present?
          # just asked for demographic data, show results
          redirect_to(current_object)
        else        
          n = next_parameter
          if n
            redirect_to survey_parameter_path(current_object, n)
          else
            # no more parameters... need to ask for demographic data
            redirect_to survey_demographics_path(current_object)
          end
        end
      end
    end
  end

  def report
    respond_to do |format|
      format.json do
        render :json => Survey.report(params[:parameter], params[:dimension], params[:selected_value]).to_json
      end
    end
  end

  def current_objects
    @current_objects ||= current_model.n_not_null #.paginate(:per_page => 20, :page => params[:page])
  end
  
  def current_object
    @current_object ||= if params[:id].present?
        current_model.find_by_slug(params[:id]) 
      elsif session[:survey_id].present?
        current_model.find(session[:survey_id])
      end
    return @current_object
  end

  private
  def next_parameter
    current = params[:survey].keys.map{|k| k.sub(/_rational_id$/, '')}.find{|k| Survey.parameter_columns.include? k.to_sym }
    Survey.next_parameter(current)
  end
  def find_parameter
    @parameter = params[:parameter] || Survey.parameter_columns.first.to_s
  end
  
  def authorize
    return if current_object.nil?
    
    unless current_object.id == session[:survey_id]
      if current_object.completed?
        redirect_to [parent_object, current_object].flatten # show survey
      else
        redirect_to parent? ? survey_group_surveys_path : surveys_path
      end
    end
  end
  
  def only_show_if_completed
    redirect_to ( parent? ? survey_group_surveys_path : surveys_path) if current_object.nil? || !current_object.completed?
  end
end
