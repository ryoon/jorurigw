class Pref::Public::Piece::CitiesController < ApplicationController
  def index
    return render :text => '' unless Site.current_item.instance_of?(Pref::Area)
    
    @cities = Site.current_item.public_children
    
    return render :text => '' if @cities.size == 0
  end
end
