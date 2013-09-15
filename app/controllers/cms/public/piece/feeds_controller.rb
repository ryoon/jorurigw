class Cms::Public::Piece::FeedsController < ApplicationController
  def index
    @uri = Site.current_piece.body.gsub(/\r\n|\n| |/, '')
  end
end
