module Digitallibrary::Public::DocsHelper

  def new_digitallib_qstring()
    ret = ""
    ret += "&cat=#{params[:cat]}" unless params[:cat].blank?
    ret += "&limit=#{params[:limit]}" unless params[:limit].blank?
    return ret
  end

  def folder_digitallib_qstring(item)
    ret = "?title_id=#{item.title_id}&cat=#{item.id}"
    ret += "&limit=#{params[:limit]}" unless params[:limit].blank?
    return ret
  end
end
