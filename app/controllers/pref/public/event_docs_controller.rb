class Pref::Public::EventDocsController < ApplicationController
  def month
    
    @calendar = Util::Date::Calendar.new params[:year].to_i, params[:month].to_i
    @calendar.year_uri  = Site.current_node.public_uri + ':year/'
    @calendar.month_uri = Site.current_node.public_uri + ':year/:month/'
    @calendar.day_uri   = Site.current_node.public_uri + ':year/:month/#day:day'
    
    @days = {}
    @calendar.days.each do |day|
      next if day[:class] =~ /Month/
      @days["#{sprintf('%02d', day[:month])}#{sprintf('%02d', day[:day])}"] = {:day => day, :docs => []}
    end
    
    doc = Pref::Doc.new.public
    doc.is_event(:year => @calendar.year, :month => @calendar.month)
    @docs = doc.find(:all)
    
    @docs.each do |doc|
      #key = doc.published_at.to_s.gsub(/....-(..)-(..).*/, '\1\2\3')
      key = doc.event_date.strftime('%m%d')
      @days[key][:docs] << doc if @days[key]
    end
    
    @days = @days.sort{|a,b| (a[0] <=> b[0])}
  end
end
