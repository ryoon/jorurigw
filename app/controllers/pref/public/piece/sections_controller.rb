class Pref::Public::Piece::SectionsController < ApplicationController
  def index
    return render :text => '' unless Site.current_item.instance_of?(Pref::Section)
    
    @sections = Site.current_item.public_children
    
    return render :text => '' if @sections.size == 0
  end
end
