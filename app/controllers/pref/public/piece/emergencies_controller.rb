class Pref::Public::Piece::EmergenciesController < ApplicationController
  def index
    item = Pref::Emergency.new.public
    @items = item.find(:all, :order => 'published_at DESC')
  end

end
