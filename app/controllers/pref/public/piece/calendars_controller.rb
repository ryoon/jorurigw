class Pref::Public::Piece::CalendarsController < ApplicationController
  def index
    @calendar = Util::Date::Calendar.new
    @calendar.year_uri  = '/event/:year/'
    @calendar.month_uri = '/event/:year/:month/'
    @calendar.day_uri   = '/event/:year/:month/#day:day'
  end
end
