class Pref::Public::Piece::CategoriesController < ApplicationController
  def index
    if Site.current_item.instance_of?(Pref::Category)
      @categories = Site.current_item.public_children
      if @categories.size == 0
        return render :text => ''
      end
    else
      item = Pref::Category.new.public
      item.and :level_no, 1
      @categories = item.find(:all)
    end
  end
end
