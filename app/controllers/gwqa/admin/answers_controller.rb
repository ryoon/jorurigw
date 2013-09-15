class Gwqa::Admin::AnswersController < ApplicationController

  include System::Controller::Scaffold
  include System::Controller::Scaffold::Recognition
  include System::Controller::Scaffold::Publication
  include System::Controller::Scaffold::Commitment

  def index

    item = Gwqa::Doc.new
    item.and :doc_type, 0
    parent = item.find(params[:parent])
    return error_auth unless parent

    @title = Gwqa::Control.find_by_id(parent.title_id)
    return error_auth unless @title

    item = Gwqa::Doc.new
    item.and :doc_type, 1
    item.and :parent_id, params[:parent]
    item.search params
    item.page params[:page], params[:limit]
    item.order  params[:id], "id"
    @items = item.find(:all)
    _index @items
  end

  def show

    item = Gwqa::Doc.new
    item.and :doc_type, 0
    parent = item.find(params[:parent])
    return error_auth unless parent

    @title = Gwqa::Control.find_by_id(parent.title_id)
    return error_auth unless @title

    item = Gwqa::Doc.new
    item.and :doc_type, 1
    item.and :parent_id, params[:parent]
    @item = item.find(params[:id])
    _show @item
  end

  def edit

    item = Gwqa::Doc.new
    item.and :doc_type, 0
    parent = item.find(params[:parent])
    return error_auth unless parent

    @title = Gwqa::Control.find_by_id(parent.title_id)
    return error_auth unless @title

    item = Gwqa::Doc.new
    item.and :doc_type, 1
    item.and :title_id, parent.title_id
    @item = item.find(params[:id])
  end

  def update
    @item = Gwqa::Doc.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Gwqa::Doc.new.find(params[:id])
    return error_gwbbs_no_title if @item.doc_type != 1
    _destroy @item
  end

end