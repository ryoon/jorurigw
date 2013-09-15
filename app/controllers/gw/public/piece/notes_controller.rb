class Gw::Public::Piece::NotesController < ApplicationController
  include System::Controller::Scaffold
  
  def index
    @items = Gw::Note.find(:all, :conditions=>"uid=#{Site.user.id}", :order=>"position")
    
    @max_notes = 20
    @num_notes = @items.size
    @display_button = true
    if @num_notes >= @max_notes
      @display_button = false
    end
    
    if flash[:note_new_error_item]
      @new_item = flash[:note_new_error_item]
    else
      @new_item = Gw::Note.new
      @new_item.set_default(Site.user.id)
    end
    if flash[:note_edit_error_item]
      @edit_item = flash[:note_edit_error_item]
    else
      @edit_item = Gw::Note.new
      @edit_item.set_default(Site.user.id)
    end
    _index @items
  end
end